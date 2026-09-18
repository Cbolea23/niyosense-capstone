import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'scan_result_screen.dart';

class AcousticScanScreen extends StatefulWidget {
  final String? imagePath;

  const AcousticScanScreen({super.key, this.imagePath});

  @override
  State<AcousticScanScreen> createState() => _AcousticScanScreenState();
}

class _AcousticScanScreenState extends State<AcousticScanScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _currentRecordingPath;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndNavigate();
    } else {
      await _startRealRecording();
    }
  }

  Future<void> _startRealRecording() async {
    try {
      // 1. Verify microphone permission
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Microphone permission is required to record tapping sound.")),
          );
        }
        return;
      }

      // 2. Prepare target file path
      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(dir.path, 'tap_${DateTime.now().millisecondsSinceEpoch}.m4a');
      _currentRecordingPath = filePath;

      // 3. Start recording real audio (AAC/M4A)
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1, // Mono tap audio
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // 4. Run countdown timer (auto-stops at 3 seconds)
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 3) {
          timer.cancel();
          await _stopRecordingAndNavigate();
        }
      });
    } catch (e) {
      debugPrint("❌ Failed to start recording: $e");
    }
  }

  Future<void> _stopRecordingAndNavigate() async {
    _timer?.cancel();
    setState(() => _isRecording = false);

    try {
      final finalPath = await _audioRecorder.stop();
      final savedPath = finalPath ?? _currentRecordingPath;

      if (savedPath != null && await File(savedPath).exists()) {
        debugPrint("🎤 Real audio recorded: $savedPath (Size: ${await File(savedPath).length()} bytes)");
        if (mounted) {
          _navigateToResult(hasAudio: true, realAudioPath: savedPath);
        }
      } else {
        if (mounted) _navigateToResult(hasAudio: false);
      }
    } catch (e) {
      debugPrint("❌ Failed to stop recording: $e");
      if (mounted) _navigateToResult(hasAudio: false);
    }
  }

  void _showIncompleteDataModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Incomplete Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Reduced accuracy warning", style: TextStyle(fontSize: 11, color: Colors.amber)),
              ],
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to proceed with only a photo scan? It is highly recommended you take an acoustic recording as well for more accurate results.",
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.mic, color: Colors.white),
                label: const Text("Record Audio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToResult(hasAudio: false);
                },
                child: const Text("Proceed with Photo Only", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToResult({required bool hasAudio, String? realAudioPath}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          imagePath: widget.imagePath,
          audioRecorded: hasAudio,
          audioPath: realAudioPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black54),
          label: const Text("Back", style: TextStyle(color: Colors.black54)),
        ),
        leadingWidth: 90,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
            Container(width: 24, height: 2, color: const Color(0xFF10B981), margin: const EdgeInsets.symmetric(horizontal: 4)),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              child: const Center(child: Text("2", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
        actions: [
          if (widget.imagePath != null)
            TextButton(
              onPressed: _showIncompleteDataModal,
              child: const Row(
                children: [
                  Text("Skip", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black45),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: _isRecording ? Colors.red : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? "Recording tapping signal..." : "Ready to record",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text("00:0$_recordingSeconds", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    28,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: _isRecording ? (20.0 + (i % 5 * 12)) : 6.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tapping Intensity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      Text("Ideal Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _isRecording ? 0.65 : 0.0,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.adjust, color: Color(0xFF10B981), size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tap the equator (middle)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
                        SizedBox(height: 2),
                        Text("Strike the widest center section of the coconut for the most accurate acoustic reading.", style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggleRecording,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(_isRecording ? "Tap to Stop" : "Start Recording", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}