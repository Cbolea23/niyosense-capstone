import 'dart:io';
import 'dart:typed_data';
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

  /// Load both TFLite model files into memory
  Future<void> loadModels() async {
    try {
      _imgInterpreter = await Interpreter.fromAsset('assets/models/img_best.tflite');
      _specInterpreter = await Interpreter.fromAsset('assets/models/spec_best.tflite');
      print("✅ TFLite models loaded successfully.");
    } catch (e) {
      print("❌ Error loading TFLite models: $e");
    }
  }

  /// Preprocesses an image file into a [1, 224, 224, 3] Float32 normalized tensor (0.0 - 1.0)
  Float32List _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception("Failed to decode image.");

    final resizedImage = img.copyResize(decodedImage, width: 224, height: 224);
    var inputBuffer = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBuffer[pixelIndex++] = pixel.r / 255.0;
        inputBuffer[pixelIndex++] = pixel.g / 255.0;
        inputBuffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return inputBuffer;
  }

  /// Runs late-fusion inference on visual photo + audio spectrogram image
  Future<PredictionResult> predict({
    required File imageFile,
    File? spectrogramFile,
    double visualWeight = 0.6,
    double confidenceThreshold = 0.65,
  }) async {
    if (!isLoaded) await loadModels();

    // 1. Process Visual Model Input
    var imgInput = _preprocessImage(imageFile).reshape([1, 224, 224, 3]);
    var imgOutput = List.filled(1 * 2, 0.0).reshape([1, 2]);
    _imgInterpreter!.run(imgInput, imgOutput);

    List<double> imgProbs = List<double>.from(imgOutput[0]);

    // 2. Process Spectrogram Model Input (if available)
    List<double> specProbs;
    if (spectrogramFile != null && await spectrogramFile.exists()) {
      var specInput = _preprocessImage(spectrogramFile).reshape([1, 224, 224, 3]);
      var specOutput = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _specInterpreter!.run(specInput, specOutput);
      specProbs = List<double>.from(specOutput[0]);
    } else {
      // Fall back to image-only inference if audio is missing
      specProbs = List.from(imgProbs);
    }

    // 3. Late Fusion Calculation: W * P_img + (1 - W) * P_spec
    double bukoProb = (visualWeight * imgProbs[0]) + ((1.0 - visualWeight) * specProbs[0]);
    double malauhogProb = (visualWeight * imgProbs[1]) + ((1.0 - visualWeight) * specProbs[1]);

    String finalLabel = bukoProb > malauhogProb ? "buko" : "malauhog";
    double highestConfidence = bukoProb > malauhogProb ? bukoProb : malauhogProb;

    // Reject non-coconut objects if confidence score falls below threshold floor
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