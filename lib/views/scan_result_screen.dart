import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/grading_log.dart';

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final String audioPath;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.audioPath,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isSaved = false;

  // Mock model predictions for Sprint 1 (Will be replaced by live TFLite in Sprint 2)
  final String _finalStage = "Mature";
  final double _confidence = 0.942; // 94.2%
  final String _visualPred = "Mature";
  final String _audioPred = "Mature";

  Future<void> _saveToSQLite() async {
    final log = GradingLog(
      uuid: const Uuid().v4(), // Standard RFC 4122 UUID v4 format for Django
      userId: 1, // Logged in Aggregator ID
      imagePath: widget.imagePath,
      audioPath: widget.audioPath,
      visualPred: _visualPred,
      audioPred: _audioPred,
      finalStage: _finalStage,
      confidence: _confidence,
      isSynced: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertScan(log);

    if (!mounted) return;

    setState(() {
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan saved to local SQLite database!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: const Color(0xFF121212),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Maturity Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.2), // Fixed invalid const
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E7D32), width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    "PROFILED MATURITY STAGE",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _finalStage,
                    style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(_confidence * 100).toStringAsFixed(1)}% Confidence",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Multimodal Predictions Breakdown
            Card(
              color: Colors.grey.shade900,
              child: ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF008080)),
                title: const Text("Visual Prediction", style: TextStyle(color: Colors.white)),
                trailing: Text(_visualPred, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),
            Card(
              color: Colors.grey.shade900,
              child: ListTile(
                leading: const Icon(Icons.graphic_eq, color: Color(0xFF008080)),
                title: const Text("Acoustic Prediction", style: TextStyle(color: Colors.white)),
                trailing: Text(_audioPred, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),

            const Spacer(),

            // Action Buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSaved ? Colors.grey : const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaved ? null : _saveToSQLite,
              child: Text(
                _isSaved ? "SAVED TO LOCAL DB" : "SAVE SCAN TO SQLITE",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Done / Return Home", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}