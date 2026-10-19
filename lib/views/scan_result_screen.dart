import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/grading_log.dart';
import '../services/tflite_service.dart';
import '../utils/app_translations.dart';
import '../utils/app_config.dart';

class ScanResultScreen extends StatefulWidget {
  final String? imagePath;
  final bool audioRecorded;
  final String? audioPath;
  final PredictionResult? precomputedResult;

  const ScanResultScreen({
    super.key,
    this.imagePath,
    this.audioRecorded = false,
    this.audioPath,
    this.precomputedResult,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isProcessing = true;
  String _finalGrade = "MATURE";
  String _visualPred = "buko";
  double _visualConf = 0.0;
  String _audioPred = "buko";
  double _audioConf = 0.0;
  double _confidence = 0.85;
  bool _isValidObject = true;

  String _currentUuid = "";
  int _bunchCount = 10;
  final TextEditingController _bunchCountController = TextEditingController(text: '10');

  final TfliteService _tfliteService = TfliteService();

  @override
  void initState() {
    super.initState();
    _runInferenceAndSave();
  }

  Future<void> _updateBunchCount(int newCount) async {
    final validCount = newCount < 1 ? 1 : (newCount > 100 ? 100 : newCount);
    setState(() {
      _bunchCount = validCount;
      _bunchCountController.text = validCount.toString();
      _bunchCountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _bunchCountController.text.length),
      );
    });
    if (_currentUuid.isNotEmpty) {
      await DatabaseHelper.instance.updateScanBunchCount(_currentUuid, validCount);
      debugPrint("🌿 Updated Bungkos count for $_currentUuid -> $validCount coconuts");
    }
  }

  Future<void> _runInferenceAndSave() async {
    try {
      PredictionResult? result = widget.precomputedResult;
      if (result == null && widget.imagePath != null && widget.imagePath!.isNotEmpty) {
        final imgFile = File(widget.imagePath!);
        File? audioFile;

        if (widget.audioRecorded && widget.audioPath != null && widget.audioPath!.isNotEmpty) {
          audioFile = File(widget.audioPath!);
        }

        result = await _tfliteService.predict(
          imageFile: imgFile,
          audioFile: audioFile,
          visualWeight: 0.50, // 50% Visual / 50% Audio (Raw V2 Baseline)
          confidenceThreshold: 0.0, // No rejection guardrails
        );
      }

      if (result != null) {
        debugPrint("🎯 FUSED PREDICTION (RAW V2): ${result.label} (Conf: ${(result.confidence * 100).toStringAsFixed(1)}%)");
        debugPrint("📸 Visual: ${result.visualLabel} (${(result.visualConfidence * 100).toStringAsFixed(1)}%) | 🎵 Audio: ${result.audioLabel} (${(result.audioConfidence * 100).toStringAsFixed(1)}%)");

        _isValidObject = true;
        _confidence = result.confidence;
        _visualPred = result.visualLabel;
        _visualConf = result.visualConfidence;
        _audioPred = widget.audioRecorded ? result.audioLabel : AppTranslations.text('skipped_audio');
        _audioConf = widget.audioRecorded ? result.audioConfidence : 0.0;
        _finalGrade = result.label.toUpperCase();
      }
    } catch (e, stack) {
      debugPrint("⚠️ Inference error: $e");
      debugPrint("$stack");
      _finalGrade = AppTranslations.text('unrecognized_object');
      _confidence = 0.0;
      _visualPred = "N/A";
      _audioPred = widget.audioRecorded ? "N/A" : AppTranslations.text('skipped_audio');
      _isValidObject = false;
    }

    // ONLY save to SQLite if all pre-inference gates and cross-model checks passed
    if (_isValidObject) {
      try {
        final deviceId = await AppConfig.getDeviceId();
        final activeBatch = await DatabaseHelper.instance.getActiveBatchSession();
        _currentUuid = const Uuid().v4();

        final log = GradingLog(
          uuid: _currentUuid,
          userId: 1,
          imagePath: widget.imagePath ?? '',
          audioPath: widget.audioPath ?? '',
          visualPred: _visualPred,
          audioPred: _audioPred,
          finalStage: _finalGrade,
          confidence: _confidence,
          isSynced: false,
          createdAt: DateTime.now().toIso8601String(),
          batchId: activeBatch?.batchId,
          deviceId: deviceId,
          bunchCount: _bunchCount,
        );

        await DatabaseHelper.instance.insertScan(log);
        debugPrint("✅ SUCCESS: Valid coconut scan saved to local SQLite! (Device: $deviceId, Bungkos: $_bunchCount)");
      } catch (dbError) {
        debugPrint("❌ Database save error: $dbError");
      }
    } else {
      debugPrint("🚫 Scan did not pass validation gates — NOT saved to SQLite.");
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _bunchCountController.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.currentLang,
      builder: (context, lang, _) {
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
                Text(
                  AppTranslations.text('scan_results_title'),
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: _isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF10B981)),
                      const SizedBox(height: 16),
                      Text(
                        AppTranslations.text('performing_inference'),
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Result Summary Card
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
                                "${AppTranslations.text('fused_confidence')}: ${(_confidence * 100).toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: _isValidObject ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image & Spectrogram Previews (Test A Verification)
                        if (widget.imagePath != null && widget.imagePath!.isNotEmpty) ...[
                          Row(
                            children: [
                              // Visual Camera Capture Preview
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("📸 Camera Photo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        File(widget.imagePath!),
                                        height: 140,
                                        width: double.infinity,
                                        cacheWidth: 400,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Audio Mel-Spectrogram Preview (Test A: Direct PNG Inspection)
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final specPath = (widget.audioPath != null && widget.audioPath!.isNotEmpty)
                                        ? widget.audioPath!.replaceAll(RegExp(r'\.wav$', caseSensitive: false), '_spectrogram.png')
                                        : null;
                                    final bool specExists = specPath != null && File(specPath).existsSync();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("🎵 Mel-Spectrogram", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: specExists
                                              ? Image.file(
                                                  File(specPath),
                                                  height: 140,
                                                  width: double.infinity,
                                                  cacheWidth: 400,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  height: 140,
                                                  color: Colors.grey.shade100,
                                                  alignment: Alignment.center,
                                                  child: const Text("Audio Skipped\nor No Tap", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black45)),
                                                ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Model Breakdown Card
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
                                    Text(
                                      AppTranslations.text('visual_model_husk'),
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    Text(
                                      "${_visualPred.toUpperCase()} (${(_visualConf * 100).toStringAsFixed(1)}%)",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.text('audio_model_spec'),
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    Text(
                                      widget.audioRecorded
                                          ? "${_audioPred.toUpperCase()} (${(_audioConf * 100).toStringAsFixed(1)}%)"
                                          : _audioPred.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppTranslations.text('storage_status'),
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                    Text(
                                      AppTranslations.text('saved_sqlite_ready'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Cluster / Bungkos Maturity Baseline + Interactive Bunch Coconut Counter Card
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.hub_outlined,
                                      color: Color(0xFF059669),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppTranslations.text('cluster_notice_title'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppTranslations.text('cluster_notice_body'),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            height: 1.45,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_isValidObject) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1, color: Color(0xFFA7F3D0)),
                                ),
                                Text(
                                  AppTranslations.text('bunch_count_label'),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppTranslations.text('bunch_count_sub'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Decrement Button (-)
                                    InkWell(
                                      onTap: () => _updateBunchCount(_bunchCount - 1),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF6EE7B7)),
                                        ),
                                        child: const Icon(Icons.remove, color: Color(0xFF065F46), size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Numeric Text Field
                                    SizedBox(
                                      width: 85,
                                      height: 42,
                                      child: TextField(
                                        controller: _bunchCountController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF065F46),
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          if (parsed != null && parsed >= 1) {
                                            _updateBunchCount(parsed);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Increment Button (+)
                                    InkWell(
                                      onTap: () => _updateBunchCount(_bunchCount + 1),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "🌿 $_bunchCount ${AppTranslations.text('bunch_count_unit')}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Quick-select presets
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [1, 8, 10, 12, 15].map((preset) {
                                    final isSelected = _bunchCount == preset;
                                    return InkWell(
                                      onTap: () => _updateBunchCount(preset),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF059669) : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF059669) : const Color(0xFFA7F3D0),
                                          ),
                                        ),
                                        child: Text(
                                          preset == 1 ? "1 (Single)" : "$preset pcs",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : const Color(0xFF065F46),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Return Home Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                          child: Text(
                            AppTranslations.text('return_home'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}