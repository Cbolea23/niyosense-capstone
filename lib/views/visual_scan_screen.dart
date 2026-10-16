import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/tflite_service.dart';
import '../utils/app_translations.dart';
import 'acoustic_scan_screen.dart';

class VisualScanScreen extends StatefulWidget {
  final CameraDescription camera;

  const VisualScanScreen({super.key, required this.camera});

  @override
  State<VisualScanScreen> createState() => _VisualScanScreenState();
}

class _VisualScanScreenState extends State<VisualScanScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  late AnimationController _shakeController;

  bool _isFlashOn = false;
  bool _isStreaming = false;
  bool _isAnalyzingFrame = false;

  // 0 = Red (Not Aligned / Invalid), 1 = Amber (Almost Aligned), 2 = Green (Locked & Aligned)
  int _alignmentTier = 0;
  double _alignmentScore = 0.0; // 0.0 to 1.0 live fit meter
  String _alignmentStatusKey = 'not_aligned_hint';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setFlashMode(FlashMode.off);
        _startLiveAlignmentStream();
      }
    });
  }

  void _startLiveAlignmentStream() {
    if (!_controller.value.isInitialized) return;
    _isStreaming = true;
    int frameCounter = 0;

    try {
      _controller.startImageStream((CameraImage image) {
        if (!_isStreaming) return;
        frameCounter++;
        // Evaluate every 6th frame (~4-5 checks/sec) for responsive HUD with 0ms UI lag
        if (frameCounter % 6 != 0) return;
        if (_isAnalyzingFrame) return;

        _isAnalyzingFrame = true;
        try {
          _checkLiveAlignment(image);
        } catch (e) {
          debugPrint("Live alignment error: $e");
        } finally {
          _isAnalyzingFrame = false;
        }
      });
    } catch (e) {
      debugPrint("Could not start live image stream: $e");
    }
  }

  List<double> _rgbToHsv(double r, double g, double b) {
    final double maxC = math.max(r, math.max(g, b));
    final double minC = math.min(r, math.min(g, b));
    final double delta = maxC - minC;

    double h = 0.0;
    if (delta > 1e-5) {
      if (maxC == r) {
        h = 60.0 * (((g - b) / delta) % 6.0);
      } else if (maxC == g) {
        h = 60.0 * (((b - r) / delta) + 2.0);
      } else {
        h = 60.0 * (((r - g) / delta) + 4.0);
      }
    }
    if (h < 0.0) h += 360.0;
    final double s = maxC <= 1e-5 ? 0.0 : (delta / maxC);
    final double v = maxC;
    return [h, s, v];
  }

  void _checkLiveAlignment(CameraImage image) {
    if (image.planes.isEmpty) return;
    final int w = image.width;
    final int h = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes.length > 1 ? image.planes[1] : null;
    final vPlane = image.planes.length > 2 ? image.planes[2] : null;

    if (uPlane == null || vPlane == null) return;

    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;
    final int uRowStride = uPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vRowStride = vPlane.bytesPerRow;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    // Sample a 10x10 grid across the camera frame (100 points total)
    // Center ROI: grid indices [2..7] x [2..7] (36 points inside circular frame)
    // Border Ring: indices 0, 1, 8, 9 (64 perimeter points outside circular frame)
    final List<List<double>> lumGrid = List.generate(
      10,
      (_) => List<double>.filled(10, 0.0),
    );

    double sumLum = 0.0;
    int centerGreenCount = 0;
    int totalCenter = 0;
    int borderGreenCount = 0;
    int totalBorder = 0;

    double sumCenterHue = 0.0;
    double sumCenterHueSq = 0.0;

    // Quadrant counters inside the center circle to check if coconut is centered
    int qTopLeft = 0;
    int qTopRight = 0;
    int qBottomLeft = 0;
    int qBottomRight = 0;

    for (int gy = 0; gy < 10; gy++) {
      final int py = ((gy + 0.5) * h / 10.0).toInt().clamp(0, h - 1);
      final int uvRow = py ~/ 2;
      for (int gx = 0; gx < 10; gx++) {
        final int px = ((gx + 0.5) * w / 10.0).toInt().clamp(0, w - 1);
        final int uvCol = px ~/ 2;

        final int yIdx = py * yRowStride + px * yPixelStride;
        final int uIdx = uvRow * uRowStride + uvCol * uPixelStride;
        final int vIdx = uvRow * vRowStride + uvCol * vPixelStride;

        if (yIdx >= yPlane.bytes.length ||
            uIdx >= uPlane.bytes.length ||
            vIdx >= vPlane.bytes.length) {
          continue;
        }

        final double yVal = yPlane.bytes[yIdx].toDouble();
        final double uVal = uPlane.bytes[uIdx].toDouble() - 128.0;
        final double vVal = vPlane.bytes[vIdx].toDouble() - 128.0;

        lumGrid[gy][gx] = yVal;
        sumLum += yVal;

        // Convert YUV (ITU-R BT.601) -> RGB [0..1] -> HSV
        final double r = ((yVal + 1.402 * vVal) / 255.0).clamp(0.0, 1.0);
        final double g =
            ((yVal - 0.344136 * uVal - 0.714136 * vVal) / 255.0).clamp(0.0, 1.0);
        final double b = ((yVal + 1.772 * uVal) / 255.0).clamp(0.0, 1.0);

        final hsv = _rgbToHsv(r, g, b);
        final double hue = hsv[0];
        final double sat = hsv[1];
        final double val = hsv[2];

        // Exact Gate 1 Green/Olive Coconut Husk HSV Criteria
        final bool isGreenHusk =
            (hue >= 32.0 && hue <= 158.0) &&
            (sat >= 0.14 && sat <= 0.92) &&
            (val >= 0.15 && val <= 0.92);

        final bool isCenter = (gx >= 2 && gx <= 7 && gy >= 2 && gy <= 7);
        if (isCenter) {
          totalCenter++;
          if (isGreenHusk) {
            centerGreenCount++;
            sumCenterHue += hue;
            sumCenterHueSq += hue * hue;
            if (gx <= 4 && gy <= 4) qTopLeft++;
            if (gx >= 5 && gy <= 4) qTopRight++;
            if (gx <= 4 && gy >= 5) qBottomLeft++;
            if (gx >= 5 && gy >= 5) qBottomRight++;
          }
        } else {
          totalBorder++;
          if (isGreenHusk) {
            borderGreenCount++;
          }
        }
      }
    }

    final double meanLum = sumLum / 100.0;
    final double centerRatio =
        totalCenter > 0 ? (centerGreenCount / totalCenter) : 0.0;
    final double borderRatio =
        totalBorder > 0 ? (borderGreenCount / totalBorder) : 0.0;

    // Hue standard deviation across green center pixels
    double hueStdDev = 0.0;
    if (centerGreenCount > 4) {
      final double meanHue = sumCenterHue / centerGreenCount;
      final double hueVar = math.max(
        0.0,
        (sumCenterHueSq / centerGreenCount) - (meanHue * meanHue),
      );
      hueStdDev = math.sqrt(hueVar);
    }

    // Center gradient roughness (scaled to match 64x64 Gate 1 roughness)
    double sumEdgeDiff = 0.0;
    int edgeCount = 0;
    for (int gy = 2; gy < 7; gy++) {
      for (int gx = 2; gx < 7; gx++) {
        final double dx = (lumGrid[gy][gx] - lumGrid[gy][gx + 1]).abs();
        final double dy = (lumGrid[gy][gx] - lumGrid[gy + 1][gx]).abs();
        sumEdgeDiff += (dx + dy);
        edgeCount++;
      }
    }
    final double edgeRoughness =
        edgeCount > 0 ? (sumEdgeDiff / edgeCount) * 0.45 : 0.0;

    // Check how many of the 4 inner circle quadrants contain coconut pixels
    int activeQuadrants = 0;
    if (qTopLeft >= 2) activeQuadrants++;
    if (qTopRight >= 2) activeQuadrants++;
    if (qBottomLeft >= 2) activeQuadrants++;
    if (qBottomRight >= 2) activeQuadrants++;

    int newTier = 0;
    double newScore = 0.0;
    String newStatusKey = 'not_aligned_hint';

    if (meanLum < 28.0) {
      // Camera lens covered or pitch dark
      newTier = 0;
      newScore = 0.08;
      newStatusKey = 'too_dark_hint';
    } else if (centerRatio < 0.25) {
      // No coconut in center circle
      newTier = 0;
      newScore = (centerRatio / 0.45).clamp(0.05, 0.30);
      newStatusKey = 'not_aligned_hint';
    } else if (borderRatio >= 0.78 && (edgeRoughness < 18.0 || hueStdDev < 3.2)) {
      // Extreme close-up or wall-to-wall solid green surface!
      newTier = 0;
      newScore = 0.20;
      newStatusKey = 'too_close_hint';
    } else if (edgeRoughness > 30.0 || (borderRatio > 0.82 && edgeRoughness > 22.0)) {
      // Grass or foliage background
      newTier = 0;
      newScore = 0.25;
      newStatusKey = 'foliage_hint';
    } else if (centerRatio >= 0.40 && edgeRoughness < 3.5 && hueStdDev < 2.4) {
      // Flat artificial green color (wall, folder, plastic)
      newTier = 0;
      newScore = 0.15;
      newStatusKey = 'flat_color_hint';
    } else if (borderRatio >= 0.68) {
      // Almost aligned, but camera is slightly too close to the coconut
      newTier = 1;
      newScore = 0.62;
      newStatusKey = 'too_close_hint';
    } else if (centerRatio < 0.42) {
      // Coconut detected, but too far / too small in the circle
      newTier = 1;
      newScore = 0.55;
      newStatusKey = 'almost_aligned_closer';
    } else if (activeQuadrants < 3) {
      // Coconut is only in half of the circle (off-center)
      newTier = 1;
      newScore = 0.68;
      newStatusKey = 'almost_aligned_center';
    } else {
      // Locked On! Coconut fills the circle with a clean background perimeter
      newTier = 2;
      final double fillBonus = ((centerRatio - 0.42) / 0.45).clamp(0.0, 0.22);
      final double borderPenalty = (borderRatio * 0.15).clamp(0.0, 0.10);
      newScore = (0.82 + fillBonus - borderPenalty).clamp(0.80, 0.98);
      newStatusKey = 'coconut_aligned';
    }

    if (mounted &&
        (newTier != _alignmentTier ||
            newStatusKey != _alignmentStatusKey ||
            (newScore - _alignmentScore).abs() > 0.04)) {
      final bool justLockedOn = (_alignmentTier != 2 && newTier == 2);
      setState(() {
        _alignmentTier = newTier;
        _alignmentScore = newScore;
        _alignmentStatusKey = newStatusKey;
      });
      if (justLockedOn) {
        HapticFeedback.selectionClick();
      }
    }
  }

  @override
  void dispose() {
    _isStreaming = false;
    _shakeController.dispose();
    _controller.setFlashMode(FlashMode.off);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      await _initializeControllerFuture;
      setState(() => _isFlashOn = !_isFlashOn);
      await _controller.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint("Flash error: $e");
    }
  }

  void _showGateRejectionDialog(String reason) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFEF2F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Visual Check Failed",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF7F1D1D),
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted && !_isStreaming) {
                _startLiveAlignmentStream();
              }
            },
            child: const Text(
              "Retake Photo",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    // If live reticle is RED (Tier 0), give immediate tactile shake warning before checking
    if (_alignmentTier == 0) {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
    } else {
      HapticFeedback.mediumImpact();
    }

    try {
      await _initializeControllerFuture;

      // Safely stop stream before taking high-res picture
      if (_isStreaming) {
        _isStreaming = false;
        try {
          await _controller.stopImageStream();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 60));
      }

      // Explicitly turn off flash after photo capture
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _isFlashOn = false);
      }

      final image = await _controller.takePicture();

      if (!mounted) return;

      // Run Gate 1: High-Res Camera Image Pixel Gate BEFORE advancing
      final String? gate1Rejection = TfliteService.validateCameraImageFile(
        File(image.path),
      );
      if (gate1Rejection != null) {
        if (mounted) {
          setState(() {
            _alignmentTier = 0;
            _alignmentScore = 0.15;
            _alignmentStatusKey = 'not_aligned_hint';
          });
        }
        _showGateRejectionDialog(gate1Rejection);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AcousticScanScreen(imagePath: image.path),
        ),
      );

      // Resume live alignment stream if user navigates back from Step 2
      if (mounted && !_isStreaming) {
        _startLiveAlignmentStream();
      }
    } catch (e) {
      if (mounted) {
        _startLiveAlignmentStream();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  void _skipToAudioOnly() async {
    if (_isStreaming) {
      _isStreaming = false;
      try {
        await _controller.stopImageStream();
      } catch (_) {}
    }
    if (_isFlashOn) {
      await _controller.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _isFlashOn = false);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AcousticScanScreen(imagePath: null),
      ),
    );
    if (mounted && !_isStreaming) {
      _startLiveAlignmentStream();
    }
  }

  Color _getTierColor() {
    if (_alignmentTier == 2) return const Color(0xFF10B981); // Emerald Green
    if (_alignmentTier == 1) return const Color(0xFFF59E0B); // Amber Warning
    return const Color(0xFFEF4444); // Crimson Red
  }

  Color _getTierBgColor() {
    if (_alignmentTier == 2) return const Color(0xFF0A2E23);
    if (_alignmentTier == 1) return const Color(0xFF2E1F0A);
    return const Color(0xFF2E0A0A);
  }

  IconData _getTierIcon() {
    if (_alignmentTier == 2) return Icons.check_circle_rounded;
    if (_alignmentTier == 1) return Icons.center_focus_strong_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        final Color frameColor = _getTierColor();
        final int fitPct = (_alignmentScore * 100).round().clamp(0, 100);

        return Scaffold(
          backgroundColor: const Color(0xFF081C15),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.text('step_1_title'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 2,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white38,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.text('step_2_title'),
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: _isFlashOn ? Colors.amber : Colors.white,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CameraPreview(_controller),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B981),
                            ),
                          );
                        },
                      ),

                      // Smart Interactive Reticle HUD with Shake Animation, Corner Brackets, & Fit Arc
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final double shakeOffset =
                              math.sin(_shakeController.value * math.pi * 4.0) *
                              12.0 *
                              (1.0 - _shakeController.value);
                          return Transform.translate(
                            offset: Offset(shakeOffset, 0),
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top HUD Lock-On Fit Pill
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: frameColor.withValues(alpha: 0.7),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _alignmentTier == 2
                                        ? Icons.lock_rounded
                                        : (_alignmentTier == 1
                                              ? Icons.tune_rounded
                                              : Icons.gps_off_rounded),
                                    color: frameColor,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _alignmentTier == 2
                                        ? 'LOCKED • $fitPct% FIT'
                                        : (_alignmentTier == 1
                                              ? 'ADJUST • $fitPct% FIT'
                                              : 'ALIGN COCONUT • $fitPct%'),
                                    style: TextStyle(
                                      color: frameColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 268x268 Smart Circular Reticle with Viewfinder Corner Brackets & Progress Arc
                            SizedBox(
                              width: 268,
                              height: 268,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(268, 268),
                                    painter: _ReticleHudPainter(
                                      color: frameColor,
                                      progress: _alignmentScore,
                                      isLocked: _alignmentTier == 2,
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: _alignmentTier == 2 ? 248 : 254,
                                    height: _alignmentTier == 2 ? 248 : 254,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: frameColor.withValues(
                                          alpha: _alignmentTier == 2
                                              ? 0.90
                                              : 0.75,
                                        ),
                                        width: _alignmentTier == 2 ? 2.2 : 2.6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: frameColor.withValues(
                                            alpha: 0.30,
                                          ),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _alignmentTier == 2
                                            ? Icons.check_rounded
                                            : Icons.add,
                                        color: frameColor,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            // Cluster / Bungkos Sampling Tip Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.hub_outlined,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppTranslations.text(
                                        'cluster_sampling_tip',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Dynamic Live Alignment Status Pill (Green = Locked, Amber = Adjust, Red = Misaligned)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getTierBgColor(),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: frameColor.withValues(alpha: 0.6),
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getTierIcon(),
                                    color: frameColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      AppTranslations.text(_alignmentStatusKey),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: frameColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.mic_none,
                              color: Colors.white70,
                              size: 28,
                            ),
                            onPressed: _skipToAudioOnly,
                          ),
                          GestureDetector(
                            onTap: _takePicture,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: frameColor,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: frameColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _alignmentTier == 2
                                      ? const Color(0xFF10B981)
                                      : (_alignmentTier == 1
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFFDC2626)),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.text('photo_auto_advance'),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReticleHudPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isLocked;

  _ReticleHudPainter({
    required this.color,
    required this.progress,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw 4 outer viewfinder corner brackets
    final Paint bracketPaint = Paint()
      ..color = color.withValues(alpha: isLocked ? 0.95 : 0.70)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double len = 22.0;
    const double r = 12.0;

    // Top-left bracket
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      bracketPaint,
    );
    // Top-right bracket
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, len),
      bracketPaint,
    );
    // Bottom-left bracket
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(len, h),
      bracketPaint,
    );
    // Bottom-right bracket
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - len),
      bracketPaint,
    );

    // 2. Draw outer progress arc around circle
    final Rect arcRect = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w - 8,
      height: h - 8,
    );
    final Paint arcPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(arcRect, -math.pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticleHudPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.progress != progress ||
        oldDelegate.isLocked != isLocked;
  }
}