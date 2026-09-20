import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'spectrogram_service.dart';

class PredictionResult {
  final String label;
  final double confidence;
  final Map<String, double> classProbabilities;
  final String visualLabel;
  final double visualConfidence;
  final String audioLabel;
  final double audioConfidence;
  final bool isValidObject;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.classProbabilities,
    required this.visualLabel,
    required this.visualConfidence,
    required this.audioLabel,
    required this.audioConfidence,
    required this.isValidObject,
  });
}

class TfliteService {
  Interpreter? _imgInterpreter;
  Interpreter? _specInterpreter;

  bool get isLoaded => _imgInterpreter != null && _specInterpreter != null;

  Future<void> loadModels() async {
    try {
      _imgInterpreter = await Interpreter.fromAsset('assets/models/img_best.tflite');
      _specInterpreter = await Interpreter.fromAsset('assets/models/spec_best.tflite');

      debugPrint("✅ TFLite models loaded successfully.");
      debugPrint("📸 Visual Model Input: ${_imgInterpreter!.getInputTensor(0).shape}");
      debugPrint("🎵 Spectrogram Model Input: ${_specInterpreter!.getInputTensor(0).shape}");
    } catch (e) {
      debugPrint("❌ Error loading TFLite models: $e");
    }
  }

  /// Preprocesses a camera photo into an NCHW [1, 3, 224, 224] Float32List tensor
  Object? _preprocessImageForInterpreter(File file, Interpreter interpreter) {
    try {
      final bytes = file.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final shape = interpreter.getInputTensor(0).shape;
      final bool isNCHW = shape.length == 4 && shape[1] == 3;
      final int targetHeight = isNCHW ? shape[2] : shape[1];
      final int targetWidth = isNCHW ? shape[3] : shape[2];

      final resized = img.copyResize(decoded, width: targetWidth, height: targetHeight);
      final int totalPixels = targetHeight * targetWidth;
      final buffer = Float32List(1 * 3 * totalPixels);

      if (isNCHW) {
        int rIdx = 0;
        int gIdx = totalPixels;
        int bIdx = 2 * totalPixels;
        for (var y = 0; y < targetHeight; y++) {
          for (var x = 0; x < targetWidth; x++) {
            final pixel = resized.getPixel(x, y);
            buffer[rIdx++] = pixel.r / 255.0;
            buffer[gIdx++] = pixel.g / 255.0;
            buffer[bIdx++] = pixel.b / 255.0;
          }
        }
      } else {
        int idx = 0;
        for (var y = 0; y < targetHeight; y++) {
          for (var x = 0; x < targetWidth; x++) {
            final pixel = resized.getPixel(x, y);
            buffer[idx++] = pixel.r / 255.0;
            buffer[idx++] = pixel.g / 255.0;
            buffer[idx++] = pixel.b / 255.0;
          }
        }
      }
      return buffer.reshape(shape);
    } catch (e) {
      debugPrint("⚠️ Could not process image: $e");
      return null;
    }
  }

  List<double> _normalizeProbs(List<double> raw) {
    double sum = raw.fold(0.0, (a, b) => a + b);
    if ((sum - 1.0).abs() < 0.05 && raw.every((v) => v >= 0.0 && v <= 1.0)) {
      return raw;
    }
    double maxVal = raw.reduce((a, b) => a > b ? a : b);
    List<double> exps = raw.map((v) => math.exp(v - maxVal)).toList();
    double expSum = exps.fold(0.0, (a, b) => a + b);
    return exps.map((e) => e / expSum).toList();
  }

  /// Runs late-fusion multimodal inference completely offline
  Future<PredictionResult> predict({
    required File imageFile,
    File? audioFile,
    double visualWeight = 0.6,
    double confidenceThreshold = 0.60,
  }) async {
    if (!isLoaded) await loadModels();

    // 1. Run Visual Model (img_best.tflite)
    final imgInput = _preprocessImageForInterpreter(imageFile, _imgInterpreter!);
    if (imgInput == null) throw Exception("Failed to decode camera photo.");

    final imgOutputShape = _imgInterpreter!.getOutputTensor(0).shape;
    final int numImgOutputs = imgOutputShape.reduce((a, b) => a * b);
    var imgOutput = List.filled(numImgOutputs, 0.0).reshape(imgOutputShape);
    _imgInterpreter!.run(imgInput, imgOutput);

    List<double> rawImgProbs = List<double>.from(imgOutputShape.length == 2 ? imgOutput[0] : imgOutput);
    List<double> imgProbs = _normalizeProbs(rawImgProbs);

    String visualLabel = imgProbs[0] >= imgProbs[1] ? "buko" : "malauhog";
    double visualConf = math.max(imgProbs[0], imgProbs[1]);

    // 2. Run Acoustic Spectrogram Model (spec_best.tflite)
    List<double> specProbs;
    String audioLabel = "N/A";
    double audioConf = 0.0;

    if (audioFile != null && await audioFile.exists()) {
      try {
        debugPrint("🎵 Generating Dart Mel-Spectrogram for: ${audioFile.path}");
        final specInput = SpectrogramService.generateSpectrogramTensor(audioFile);

        final specOutputShape = _specInterpreter!.getOutputTensor(0).shape;
        final int numSpecOutputs = specOutputShape.reduce((a, b) => a * b);
        var specOutput = List.filled(numSpecOutputs, 0.0).reshape(specOutputShape);
        _specInterpreter!.run(specInput, specOutput);

        List<double> rawSpecProbs = List<double>.from(specOutputShape.length == 2 ? specOutput[0] : specOutput);
        specProbs = _normalizeProbs(rawSpecProbs);

        audioLabel = specProbs[0] >= specProbs[1] ? "buko" : "malauhog";
        audioConf = math.max(specProbs[0], specProbs[1]);
        debugPrint("🎵 Real Audio Prediction: $audioLabel (${(audioConf * 100).toStringAsFixed(1)}%)");
      } catch (e) {
        debugPrint("⚠️ Audio spectrogram inference failed, falling back to visual: $e");
        specProbs = List.from(imgProbs);
        audioLabel = visualLabel;
        audioConf = visualConf;
      }
    } else {
      specProbs = List.from(imgProbs);
      audioLabel = "N/A (Skipped)";
      audioConf = visualConf;
    }

    // 3. Late Fusion: W * P_visual + (1 - W) * P_audio
    double bukoProb = (visualWeight * imgProbs[0]) + ((1.0 - visualWeight) * specProbs[0]);
    double malauhogProb = (visualWeight * imgProbs[1]) + ((1.0 - visualWeight) * specProbs[1]);

    String finalLabel = bukoProb >= malauhogProb ? "buko" : "malauhog";
    double highestConfidence = math.max(bukoProb, malauhogProb);
    bool isValid = highestConfidence >= confidenceThreshold;

    return PredictionResult(
      label: isValid ? finalLabel : "Invalid Object",
      confidence: highestConfidence,
      classProbabilities: {
        "buko": bukoProb,
        "malauhog": malauhogProb,
      },
      visualLabel: visualLabel,
      visualConfidence: visualConf,
      audioLabel: audioLabel,
      audioConfidence: audioConf,
      isValidObject: isValid,
    );
  }

  void dispose() {
    _imgInterpreter?.close();
    _specInterpreter?.close();
  }
}