import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionResult {
  final String label;
  final double confidence;
  final Map<String, double> classProbabilities;
  final bool isValidObject;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.classProbabilities,
    required this.isValidObject,
  });
}

class TfliteService {
  Interpreter? _imgInterpreter;
  Interpreter? _specInterpreter;

  bool get isLoaded => _imgInterpreter != null && _specInterpreter != null;

  /// Load both TFLite model files into memory and print their tensor shapes
  Future<void> loadModels() async {
    try {
      _imgInterpreter = await Interpreter.fromAsset('assets/models/img_best.tflite');
      _specInterpreter = await Interpreter.fromAsset('assets/models/spec_best.tflite');

      final imgInput = _imgInterpreter!.getInputTensor(0);
      final imgOutput = _imgInterpreter!.getOutputTensor(0);
      debugPrint("✅ TFLite models loaded successfully.");
      debugPrint("📸 Visual Model: Input=${imgInput.shape} (${imgInput.type}), Output=${imgOutput.shape}");

      final specInput = _specInterpreter!.getInputTensor(0);
      final specOutput = _specInterpreter!.getOutputTensor(0);
      debugPrint("🎵 Spectrogram Model: Input=${specInput.shape} (${specInput.type}), Output=${specOutput.shape}");
    } catch (e) {
      debugPrint("❌ Error loading TFLite models: $e");
    }
  }

  /// Dynamically preprocesses an image to match the interpreter's exact input shape
  /// Handles both NCHW ([1, 3, H, W]) and NHWC ([1, H, W, 3]) formats automatically.
  Object? _preprocessImageForInterpreter(File file, Interpreter interpreter) {
    try {
      final bytes = file.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final shape = interpreter.getInputTensor(0).shape; // e.g. [1, 3, 224, 224] or [1, 224, 224, 3]
      final bool isNCHW = shape.length == 4 && shape[1] == 3;
      final int targetHeight = isNCHW ? shape[2] : shape[1];
      final int targetWidth = isNCHW ? shape[3] : shape[2];

      final resized = img.copyResize(decoded, width: targetWidth, height: targetHeight);
      final int totalPixels = targetHeight * targetWidth;
      final buffer = Float32List(1 * 3 * totalPixels);

      if (isNCHW) {
        // Planar format: RRR... GGG... BBB...
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
        // Interleaved format: RGB, RGB, RGB...
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
      debugPrint("⚠️ Could not process file as image: $e");
      return null;
    }
  }

  /// Normalizes logits into probabilities using Softmax if needed
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

  /// Runs late-fusion inference on visual photo + audio spectrogram
  Future<PredictionResult> predict({
    required File imageFile,
    File? spectrogramFile,
    double visualWeight = 0.6,
    double confidenceThreshold = 0.60,
  }) async {
    if (!isLoaded) await loadModels();

    // 1. Process Visual Model
    final imgInput = _preprocessImageForInterpreter(imageFile, _imgInterpreter!);
    if (imgInput == null) {
      throw Exception("Failed to decode camera photo as an image.");
    }

    final imgOutputShape = _imgInterpreter!.getOutputTensor(0).shape;
    final int numImgOutputs = imgOutputShape.reduce((a, b) => a * b);
    var imgOutput = List.filled(numImgOutputs, 0.0).reshape(imgOutputShape);
    _imgInterpreter!.run(imgInput, imgOutput);

    List<double> rawImgProbs = List<double>.from(imgOutputShape.length == 2 ? imgOutput[0] : imgOutput);
    List<double> imgProbs = _normalizeProbs(rawImgProbs);

    // 2. Process Spectrogram Model (safely check if file is an actual image, e.g. PNG/JPG)
    List<double> specProbs;
    Object? specInput;
    if (spectrogramFile != null && await spectrogramFile.exists()) {
      specInput = _preprocessImageForInterpreter(spectrogramFile, _specInterpreter!);
    }

    if (specInput != null) {
      final specOutputShape = _specInterpreter!.getOutputTensor(0).shape;
      final int numSpecOutputs = specOutputShape.reduce((a, b) => a * b);
      var specOutput = List.filled(numSpecOutputs, 0.0).reshape(specOutputShape);
      _specInterpreter!.run(specInput, specOutput);

      List<double> rawSpecProbs = List<double>.from(specOutputShape.length == 2 ? specOutput[0] : specOutput);
      specProbs = _normalizeProbs(rawSpecProbs);
    } else {
      // Audio is an .m4a raw audio file (not an image spectrogram), fall back to visual model
      specProbs = List.from(imgProbs);
    }

    // 3. Late Fusion Calculation: W * P_img + (1 - W) * P_spec
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
      isValidObject: isValid,
    );
  }

  void dispose() {
    _imgInterpreter?.close();
    _specInterpreter?.close();
  }
}