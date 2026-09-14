import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/grading_log.dart';

class ScanResultScreen extends StatefulWidget {
  final String? imagePath;
  final bool audioRecorded;

  const ScanResultScreen({super.key, this.imagePath, required this.audioRecorded});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isSaving = true;
  final String _finalGrade = "Mature";
  final double _confidence = 0.942;

  @override
  void initState() {
    super.initState();
    _saveScanToDatabase();
  }

  Future<void> _saveScanToDatabase() async {
    // Construct a GradingLog instance matching the existing model and database schema
    final log = GradingLog(
      uuid: const Uuid().v4(),
      userId: 1,
      imagePath: widget.imagePath ?? '',
      audioPath: widget.audioRecorded ? 'sample_audio.m4a' : '',
      visualPred: widget.imagePath != null ? 'Mature' : 'N/A',
      audioPred: widget.audioRecorded ? 'Mature' : 'N/A',
      finalStage: _finalGrade,
      confidence: _confidence,
      isSynced: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Save to SQLite via DatabaseHelper.insertScan
    await DatabaseHelper.instance.insertScan(log);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Scan Results", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF10B981)),
                  const SizedBox(height: 8),
                  Text(_finalGrade.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                  const SizedBox(height: 4),
                  Text("Confidence Score: ${(_confidence * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.w600)),
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
                        const Text("Visual Prediction", style: TextStyle(color: Colors.black54)),
                        Text(widget.imagePath != null ? "Mature" : "N/A (Skipped)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Audio Prediction", style: TextStyle(color: Colors.black54)),
                        Text(widget.audioRecorded ? "Mature" : "N/A (Skipped)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Storage Status", style: TextStyle(color: Colors.black54)),
                        Text("Saved Locally (SQLite)", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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