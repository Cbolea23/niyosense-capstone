import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import '../services/tflite_service.dart';
import '../utils/app_translations.dart';
import 'scan_result_screen.dart';

class AcousticScanScreen extends StatefulWidget {
  final String? imagePath;

  const AcousticScanScreen({super.key, this.imagePath});

  @override
  State<AcousticScanScreen> createState() => _AcousticScanScreenState();
}

class _AcousticScanScreenState extends State<AcousticScanScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TfliteService _tfliteService = TfliteService();

  bool _isRecording = false;
  bool _isValidating = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _currentRecordingPath;

  StreamSubscription<Amplitude>? _amplitudeSub;
  double _currentAmplitudeLevel = 0.0;
  int _knocksDetected = 0;
  int _lastKnockTimestamp = 0;
  final List<double> _waveformHeights = List.filled(28, 6.0);

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _timer?.cancel();
    _audioRecorder.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isValidating) return;
    if (_isRecording) {
      await _stopRecordingAndNavigate();
    } else {
      await _startRealRecording();
    }
  }

  Future<void> _startRealRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppTranslations.text('mic_permission_req'))),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      // Record directly to .wav at 22050 Hz matching Wayne's training dataset
      final filePath = path.join(dir.path, 'tap_${DateTime.now().millisecondsSinceEpoch}.wav');
      _currentRecordingPath = filePath;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100, // Standard native sample rate across all Android devices
          numChannels: 1, // Mono audio
          autoGain: false, // Disable automatic gain distortion
          echoCancel: false, // Disable echo cancellation
          noiseSuppress: false, // Disable noise suppression that silences taps
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.unprocessed, // Disables OS aggressive noise gates
          ),
        ),
        path: filePath,
      );

      _knocksDetected = 0;
      _currentAmplitudeLevel = 0.0;
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen((amp) {
        if (!_isRecording || !mounted) return;
        // Convert dBFS (-50 dBFS to 0 dBFS) to 0.0 .. 1.0 range
        final double normalized = ((amp.current + 50.0) / 50.0).clamp(0.0, 1.0);

        // Detect sharp percussive knock spike: current > -18.5 dBFS with 260ms cooldown
        final int now = DateTime.now().millisecondsSinceEpoch;
        if (amp.current > -18.5 && (now - _lastKnockTimestamp) > 260) {
          _lastKnockTimestamp = now;
          _knocksDetected++;
          HapticFeedback.lightImpact();
        }

        setState(() {
          _currentAmplitudeLevel = normalized;
          for (int i = 0; i < 27; i++) {
            _waveformHeights[i] = _waveformHeights[i + 1];
          }
          _waveformHeights[27] = (8.0 + normalized * 74.0).clamp(8.0, 84.0);
        });
      });

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Wayne's Librosa pipeline uses 4.0s of audio
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 4) {
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
    _amplitudeSub?.cancel();
    setState(() => _isRecording = false);

    try {
      final finalPath = await _audioRecorder.stop();
      final savedPath = finalPath ?? _currentRecordingPath;

      if (savedPath != null && await File(savedPath).exists()) {
        debugPrint("🎤 Real 4s WAV recorded: $savedPath (Size: ${await File(savedPath).length()} bytes)");
        if (mounted) {
          await _validateAndNavigateToResult(hasAudio: true, realAudioPath: savedPath);
        }
      } else {
        if (mounted) await _validateAndNavigateToResult(hasAudio: false);
      }
    } catch (e) {
      debugPrint("❌ Failed to stop recording: $e");
      if (mounted) await _validateAndNavigateToResult(hasAudio: false);
    }
  }

  void _showRejectionError(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
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
                "Scan Validation Failed",
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
          if (reason.contains("disagree"))
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF991B1B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Return to camera for full rescan
              },
              child: const Text("Retake Photo", style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Record Tap Again", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.text('incomplete_data_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    AppTranslations.text('reduced_accuracy_warning'),
                    style: const TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          AppTranslations.text('incomplete_data_desc'),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
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
                label: Text(
                  AppTranslations.text('record_audio_btn'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
                  _validateAndNavigateToResult(hasAudio: false);
                },
                child: Text(
                  AppTranslations.text('proceed_photo_only_btn'),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _validateAndNavigateToResult({required bool hasAudio, String? realAudioPath}) async {
    if (widget.imagePath == null || widget.imagePath!.isEmpty) {
      _showRejectionError("No coconut detected. Center a green coconut in the frame.");
      return;
    }

    setState(() => _isValidating = true);
    try {
      final imgFile = File(widget.imagePath!);
      final File? audFile = (hasAudio && realAudioPath != null && realAudioPath.isNotEmpty)
          ? File(realAudioPath)
          : null;

      final result = await _tfliteService.predict(
        imageFile: imgFile,
        audioFile: audFile,
        visualWeight: 0.30, // 30% Visual / 70% Audio
        confidenceThreshold: 0.65,
      );

      if (!mounted) return;
      setState(() => _isValidating = false);

      if (!result.isValidObject) {
        // Gate 1, Gate 2, or Gate 3 failed -> Abort immediately! Do NOT navigate and do NOT save to SQLite!
        _showRejectionError(
          result.rejectionReason ?? "Inconclusive Scan: Visual and audio readings disagree. Please rescan.",
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultScreen(
            imagePath: widget.imagePath,
            audioRecorded: hasAudio,
            audioPath: realAudioPath,
            precomputedResult: result,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isValidating = false);
        _showRejectionError("No acoustic tap detected in spectrogram. Knock the coconut shoulder 3 times.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.black54),
              label: Text(AppTranslations.text('back'), style: const TextStyle(color: Colors.black54)),
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
                  child: Row(
                    children: [
                      Text(AppTranslations.text('skip'), style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.black45),
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
                            _isRecording ? AppTranslations.text('recording_tap_signal') : AppTranslations.text('ready_to_record'),
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text("00:0$_recordingSeconds", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                if (_isRecording) ...[
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_knocksDetected >= 2 && _knocksDetected <= 5)
                          ? const Color(0xFF0A2E23)
                          : const Color(0xFF2E1F0A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_knocksDetected >= 2 && _knocksDetected <= 5)
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (_knocksDetected >= 2 && _knocksDetected <= 5)
                              ? Icons.check_circle_rounded
                              : Icons.touch_app_rounded,
                          color: (_knocksDetected >= 2 && _knocksDetected <= 5)
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${AppTranslations.text('knocks_detected')}: $_knocksDetected / 3–4",
                          style: TextStyle(
                            color: (_knocksDetected >= 2 && _knocksDetected <= 5)
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          duration: const Duration(milliseconds: 60),
                          width: 4,
                          height: _isRecording ? _waveformHeights[i] : 6.0,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _waveformHeights[i] > 40.0
                                ? const Color(0xFF34D399)
                                : const Color(0xFF10B981),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppTranslations.text('tapping_intensity'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            _isRecording
                                ? (_currentAmplitudeLevel > 0.88
                                    ? "Too Loud!"
                                    : (_currentAmplitudeLevel >= 0.32
                                        ? "Good Volume ✓"
                                        : "Tap Firmly"))
                                : AppTranslations.text('ideal_range'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _isRecording
                                  ? (_currentAmplitudeLevel > 0.88
                                      ? Colors.red
                                      : (_currentAmplitudeLevel >= 0.32
                                          ? const Color(0xFF10B981)
                                          : Colors.grey))
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _isRecording ? _currentAmplitudeLevel : 0.0,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _currentAmplitudeLevel > 0.88
                                ? const Color(0xFFEF4444)
                                : (_currentAmplitudeLevel >= 0.32
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF9CA3AF)),
                          ),
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
                  child: Row(
                    children: [
                      const Icon(Icons.adjust, color: Color(0xFF10B981), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.text('tap_equator_title'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppTranslations.text('tap_equator_desc'),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                            ),
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
                      Text(
                        _isRecording ? AppTranslations.text('tap_to_stop') : AppTranslations.text('start_recording'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}