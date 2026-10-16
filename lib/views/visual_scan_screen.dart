import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
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

class _VisualScanScreenState extends State<VisualScanScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isStreaming = false;
  bool _isAnalyzingFrame = false;
  bool _isAligned = false;
  String _alignmentStatusKey = 'not_aligned_hint';

  @override
  void initState() {
    super.initState();
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
        // Throttle to every 8th frame (~3-4 checks/sec) for 0ms UI delay
        if (frameCounter % 8 != 0) return;
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

  void _checkLiveAlignment(CameraImage image) {
    if (image.planes.isEmpty) return;
    final int w = image.width;
    final int h = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes.length > 1 ? image.planes[1] : null;
    final vPlane = image.planes.length > 2 ? image.planes[2] : null;

    if (uPlane == null || vPlane == null) return;

    final int uRowStride = uPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vRowStride = vPlane.bytesPerRow;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    bool isGreenAt(int px, int py) {
      final int yIdx = py * yPlane.bytesPerRow + px * (yPlane.bytesPerPixel ?? 1);
      final int uvRow = py ~/ 2;
      final int uvCol = px ~/ 2;
      final int uIdx = uvRow * uRowStride + uvCol * uPixelStride;
      final int vIdx = uvRow * vRowStride + uvCol * vPixelStride;

      if (yIdx >= yPlane.bytes.length || uIdx >= uPlane.bytes.length || vIdx >= vPlane.bytes.length) {
        return false;
      }

      final int yVal = yPlane.bytes[yIdx];
      final int uVal = uPlane.bytes[uIdx];
      final int vVal = vPlane.bytes[vIdx];

      // Green husk in YUV: U < 118, V < 122, Y in [35, 235]
      return (uVal < 118) && (vVal < 122) && (yVal >= 35 && yVal <= 235);
    }

    // 1. Sample 16 Center Grid Points (Central 40% box)
    int centerGreen = 0;
    const centerFactors = [0.38, 0.46, 0.54, 0.62];
    for (final fy in centerFactors) {
      for (final fx in centerFactors) {
        if (isGreenAt((w * fx).toInt(), (h * fy).toInt())) {
          centerGreen++;
        }
      }
    }

    // 2. Sample 16 Outer Border Points (Outer 10% corners and margins)
    int borderGreen = 0;
    final borderPoints = [
      // 4 corners
      Point((w * 0.08).toInt(), (h * 0.08).toInt()),
      Point((w * 0.92).toInt(), (h * 0.08).toInt()),
      Point((w * 0.08).toInt(), (h * 0.92).toInt()),
      Point((w * 0.92).toInt(), (h * 0.92).toInt()),
      // 4 mid-edges
      Point((w * 0.50).toInt(), (h * 0.06).toInt()),
      Point((w * 0.50).toInt(), (h * 0.94).toInt()),
      Point((w * 0.06).toInt(), (h * 0.50).toInt()),
      Point((w * 0.94).toInt(), (h * 0.50).toInt()),
      // 8 additional border points
      Point((w * 0.25).toInt(), (h * 0.06).toInt()),
      Point((w * 0.75).toInt(), (h * 0.06).toInt()),
      Point((w * 0.25).toInt(), (h * 0.94).toInt()),
      Point((w * 0.75).toInt(), (h * 0.94).toInt()),
      Point((w * 0.06).toInt(), (h * 0.25).toInt()),
      Point((w * 0.06).toInt(), (h * 0.75).toInt()),
      Point((w * 0.94).toInt(), (h * 0.25).toInt()),
      Point((w * 0.94).toInt(), (h * 0.75).toInt()),
    ];

    for (final pt in borderPoints) {
      if (isGreenAt(pt.x, pt.y)) {
        borderGreen++;
      }
    }

    final double centerRatio = centerGreen / 16.0;
    final double borderRatio = borderGreen / 16.0;

    bool aligned = false;
    String statusKey = 'not_aligned_hint';

    if (centerRatio < 0.35) {
      // Nothing green in center
      aligned = false;
      statusKey = 'not_aligned_hint'; // "Position coconut inside circle"
    } else if (borderRatio >= 0.75) {
      // The entire camera view is green (too close or solid green wall/paper)
      aligned = false;
      statusKey = 'too_close_hint'; // "Too close! Step back to fit circle"
    } else {
      // Center is green husk, and border is background/shadows!
      aligned = true;
      statusKey = 'coconut_aligned'; // "Coconut Aligned • Ready to Capture"
    }

    if (mounted && (aligned != _isAligned || statusKey != _alignmentStatusKey)) {
      setState(() {
        _isAligned = aligned;
        _alignmentStatusKey = statusKey;
      });
    }
  }

  @override
  void dispose() {
    _isStreaming = false;
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
              decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Visual Check Failed",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        content: Text(
          reason,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF7F1D1D), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted && !_isStreaming) {
                _startLiveAlignmentStream();
              }
            },
            child: const Text("Retake Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
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
      final String? gate1Rejection = TfliteService.validateCameraImageFile(File(image.path));
      if (gate1Rejection != null) {
        if (mounted) {
          setState(() {
            _isAligned = false;
            _alignmentStatusKey = 'not_aligned_hint';
          });
        }
        _showGateRejectionDialog(gate1Rejection);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AcousticScanScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      if (mounted) {
        _startLiveAlignmentStream();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AcousticScanScreen(imagePath: null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        final Color frameColor = _isAligned ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Scaffold(
          backgroundColor: const Color(0xFF081C15),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                  child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.text('step_1_title'),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(width: 40, height: 2, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white38, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text('2', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.text('step_2_title'),
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: _isFlashOn ? Colors.amber : Colors.white),
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
                          if (snapshot.connectionState == ConnectionState.done) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CameraPreview(_controller),
                            );
                          }
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                        },
                      ),

                      // Dynamic Live Alignment Circular Frame (Turns RED if not aligned / too close)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: frameColor,
                            width: _isAligned ? 2.0 : 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: frameColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: frameColor,
                            size: 28,
                          ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.hub_outlined, color: Color(0xFF10B981), size: 14),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppTranslations.text('cluster_sampling_tip'),
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

                            // Dynamic Live Alignment Status Pill (Green = Aligned, Red = Misaligned/Too Close)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: _isAligned ? const Color(0xFF0A2E23) : const Color(0xFF2E0A0A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: frameColor.withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAligned ? Icons.check_circle : Icons.warning_amber_rounded,
                                    color: frameColor,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppTranslations.text(_alignmentStatusKey),
                                    style: TextStyle(
                                      color: frameColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                            icon: const Icon(Icons.mic_none, color: Colors.white70, size: 28),
                            onPressed: _skipToAudioOnly,
                          ),
                          GestureDetector(
                            onTap: _takePicture,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
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
                                    color: frameColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _isAligned ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppTranslations.text('photo_auto_advance'),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
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