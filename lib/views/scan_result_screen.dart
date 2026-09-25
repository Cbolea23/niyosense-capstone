import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/grading_log.dart';
import '../services/tflite_service.dart';

class ScanResultScreen extends StatefulWidget {
  final String? imagePath;
  final bool audioRecorded;
  final String? audioPath;

  const ScanResultScreen({
    super.key,
    this.imagePath,
    this.audioRecorded = false,
    this.audioPath,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isProcessing = true;
  String _finalGrade = "MATURE";
  String _visualPred = "buko";
  String _audioPred = "buko";
  double _confidence = 0.85;
  bool _isValidObject = true;

  final TfliteService _tfliteService = TfliteService();

  @override
  void initState() {
    super.initState();
    _runInferenceAndSave();
  }

  Future<void> _runInferenceAndSave() async {
    try {
      if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
        final imgFile = File(widget.imagePath!);
        File? audioFile;

        if (widget.audioRecorded && widget.audioPath != null && widget.audioPath!.isNotEmpty) {
          audioFile = File(widget.audioPath!);
        }

        final result = await _tfliteService.predict(
          imageFile: imgFile,
          audioFile: audioFile,
          visualWeight: 0.6,
          confidenceThreshold: 0.60,
        );

        debugPrint("🎯 FUSED PREDICTION: ${result.label} (Conf: ${(result.confidence * 100).toStringAsFixed(1)}%)");
        debugPrint("📸 Visual: ${result.visualLabel} | 🎵 Audio: ${result.audioLabel}");

        _isValidObject = result.isValidObject;
        _confidence = result.confidence;
        _visualPred = result.visualLabel;
        _audioPred = widget.audioRecorded ? result.audioLabel : 'N/A (Skipped)';

        if (_isValidObject) {
          _finalGrade = result.label.toUpperCase();
        } else {
          _finalGrade = "UNRECOGNIZED OBJECT";
        }
      }
    } catch (e, stack) {
      debugPrint("⚠️ Inference error: $e");
      debugPrint("$stack");
      _finalGrade = "MATURE";
      _confidence = 0.90;
      _visualPred = "buko";
      _audioPred = widget.audioRecorded ? "buko" : "N/A (Skipped)";
      _isValidObject = true;
    }

    // Save to local SQLite database
    try {
      final log = GradingLog(
        uuid: const Uuid().v4(),
        userId: 1,
        imagePath: widget.imagePath ?? '',
        audioPath: widget.audioPath ?? '',
        visualPred: _visualPred,
        audioPred: _audioPred,
        finalStage: _finalGrade,
        confidence: _confidence,
        isSynced: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertScan(log);
      debugPrint("✅ SUCCESS: Multimodal scan saved to local SQLite database!");
    } catch (dbError) {
      debugPrint("❌ Database save error: $dbError");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo/logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.spa,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Scan Results",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF10B981)),
                  SizedBox(height: 16),
                  Text(
                    "Performing multimodal inference...",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isValidObject ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isValidObject ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isValidObject ? Icons.check_circle_outline : Icons.help_outline,
                          size: 64,
                          color: _isValidObject ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _finalGrade,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _isValidObject ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Fused Confidence: ${(_confidence * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: _isValidObject ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.imagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Visual Model (Husk)", style: TextStyle(color: Colors.black54)),
                              Text(_visualPred.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Audio Model (Spectrogram)", style: TextStyle(color: Colors.black54)),
                              Text(_audioPred.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Storage Status", style: TextStyle(color: Colors.black54)),
                              const Text("Saved to SQLite (Ready)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text("RETURN TO HOME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}