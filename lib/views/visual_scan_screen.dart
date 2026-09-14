import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
                          const Text('Step 1: Visual', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          const Text('Step 2: Acoustic', style: TextStyle(color: Colors.white38, fontSize: 11)),
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
                    bottom: 20,
                    child: Column(
                      children: [
                        const Text("Position coconut within frame", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2E23),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text("AI Ready • Step 1 of 2", style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
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
                  const Text("Photo taken → auto-advances to Step 2: Acoustic →", style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}