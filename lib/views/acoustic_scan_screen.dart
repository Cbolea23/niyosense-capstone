import 'package:flutter/material.dart';
import 'scan_result_screen.dart';

class AcousticScanScreen extends StatefulWidget {
  final String imagePath;

  const AcousticScanScreen({super.key, required this.imagePath});

  @override
  State<AcousticScanScreen> createState() => _AcousticScanScreenState();
}

class _AcousticScanScreenState extends State<AcousticScanScreen> {
  bool _isRecording = false;
  bool _recordingComplete = false;

  void _toggleRecording() async {
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });
      // Simulate 3 seconds of audio recording / tapping
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Acoustic Tapping Scan'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center, // Fixed typo here
          children: [
            const Text(
              "TAP COCONUT 3 TIMES",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording
                  ? "Recording acoustic vibration..."
                  : _recordingComplete
                  ? "Audio capture complete!"
                  : "Press the microphone button below to start tapping.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Waveform Visualizer Placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26, // Fixed black25 here
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isRecording ? const Color(0xFF2E7D32) : Colors.grey.shade800),
              ),
              child: Center(
                child: Icon(
                  Icons.graphic_eq,
                  size: 64,
                  color: _isRecording ? const Color(0xFF008080) : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Record Button
            GestureDetector(
              onTap: _toggleRecording,
              child: CircleAvatar(
                radius: 42,
                backgroundColor: _isRecording ? Colors.red : const Color(0xFF2E7D32),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Analyze / Next Button
            if (_recordingComplete)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScanResultScreen(
                        imagePath: widget.imagePath,
                        audioPath: "/mock/path/sample_tap.m4a",
                      ),
                    ),
                  );
                },
                child: const Text("ANALYZE MATURITY", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}