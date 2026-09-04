import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'scan_result_screen.dart';

class AcousticScanScreen extends StatefulWidget {
  final String imagePath;

  const AcousticScanScreen({super.key, required this.imagePath});

  @override
  State<AcousticScanScreen> createState() => _AcousticScanScreenState();
}

class _AcousticScanScreenState extends State<AcousticScanScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _recordingComplete = false;
  String? _realAudioPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRealRecording() async {
    // 1. Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record tapping sound.')),
        );
      }
      return;
    }

    // 2. Check if recorder has permission
    if (await _audioRecorder.hasPermission()) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/acoustic_tap_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 3. Start recording AAC/M4A audio
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingComplete = false;
      });

      // Record for 3 seconds while user taps coconut
      await Future.delayed(const Duration(seconds: 3));

      // 4. Stop recording and retrieve saved file path
      final String? path = await _audioRecorder.stop();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingComplete = true;
          _realAudioPath = path;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "TAP COCONUT 3 TIMES",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording
                  ? "Recording microphone audio..."
                  : _recordingComplete
                  ? "Audio recording saved!"
                  : "Press the microphone button below and tap the coconut.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // Waveform Visualizer Placeholder
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isRecording ? Colors.red : Colors.grey.shade800),
              ),
              child: Center(
                child: Icon(
                  Icons.graphic_eq,
                  size: 64,
                  color: _isRecording ? Colors.red : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Record Trigger
            GestureDetector(
              onTap: _isRecording ? null : _startRealRecording,
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
            if (_recordingComplete && _realAudioPath != null)
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
                        imagePath: widget.imagePath,   // Real photo from Camera
                        audioPath: _realAudioPath!,   // Real .m4a recording from Mic
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