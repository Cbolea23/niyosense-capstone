import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class VisualScanScreen extends StatefulWidget {
  final CameraDescription camera;

  const VisualScanScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _VisualScanScreenState createState() => _VisualScanScreenState();
}

class _VisualScanScreenState extends State<VisualScanScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera Preview
                Positioned.fill(child: CameraPreview(_controller)),

                // Figma Reticle Framing Overlay
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.width * 0.75,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF008080), width: 3), // Teal Accent
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10, left: 10,
                          child: Text("ALIGN COCONUT HERE",
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Capture Trigger Controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.large(
                      backgroundColor: const Color(0xFF2E7D32), // Green
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller.takePicture();
                          // Navigate to Audio Capture / Acoustic Processing
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Icon(Icons.camera_alt, size: 36, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}