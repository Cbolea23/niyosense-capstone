import 'dart:io';
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
      }
    });
  }

  @override
  void dispose() {
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Retake Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      // Explicitly turn off flash after photo capture
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _isFlashOn = false);
      }

      if (!mounted) return;

      // Run Gate 1: Camera Image Pixel Gate BEFORE advancing to Step 2
      final String? gate1Rejection = TfliteService.validateCameraImageFile(File(image.path));
      if (gate1Rejection != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  void _skipToAudioOnly() async {
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
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Color(0xFF10B981), size: 28),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            Text(
                              AppTranslations.text('position_coconut'),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),

                            // Cluster / Bungkos Sampling Tip Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
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

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A2E23),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppTranslations.text('ai_ready_step1'),
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
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
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 4),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
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