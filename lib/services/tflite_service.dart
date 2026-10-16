import 'dart:io';
import 'dart:math' as math;
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
  final String? rejectionReason;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.classProbabilities,
    required this.visualLabel,
    required this.visualConfidence,
    required this.audioLabel,
    required this.audioConfidence,
    required this.isValidObject,
    this.rejectionReason,
  });
}

class TfliteService {
  Interpreter? _imgInterpreter;
  Interpreter? _specInterpreter;

  bool get isLoaded => _imgInterpreter != null && _specInterpreter != null;

  Future<void> loadModels() async {
    try {
      _imgInterpreter = await Interpreter.fromAsset('assets/models/img_best_v2.tflite');
      _specInterpreter = await Interpreter.fromAsset('assets/models/spec_best_v2.tflite');

      debugPrint("✅ TFLite V2 models loaded successfully.");
      debugPrint("📸 Visual Model Input: ${_imgInterpreter!.getInputTensor(0).shape}");
      debugPrint("🎵 Spectrogram Model Input: ${_specInterpreter!.getInputTensor(0).shape}");
    } catch (e) {
      debugPrint("❌ Error loading TFLite models: $e");
    }
  }

  /// Helper: Converts RGB (0.0-1.0) to HSV [Hue (0-360°), Saturation (0-1), Value (0-1)]
  static List<double> _rgbToHsv(double r, double g, double b) {
    final double maxC = math.max(r, math.max(g, b));
    final double minC = math.min(r, math.min(g, b));
    final double delta = maxC - minC;

    double h = 0.0;
    if (delta > 1e-6) {
      if (maxC == r) {
        h = 60.0 * (((g - b) / delta) % 6.0);
      } else if (maxC == g) {
        h = 60.0 * (((b - r) / delta) + 2.0);
      } else {
        h = 60.0 * (((r - g) / delta) + 4.0);
      }
      if (h < 0.0) h += 360.0;
    }

    final double s = maxC <= 1e-6 ? 0.0 : (delta / maxC);
    final double v = maxC;
    return [h, s, v];
  }

  /// GATE 1: CAMERA IMAGE PIXEL GATE (Blocks Non-Coconuts, Faces, Black Screens, & Grass)
  /// Downsamples photo to 64x64 RGB pixels and returns null if valid, or the exact rejection message if invalid.
  static String? validateCameraImageFile(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return "Camera obstructed or invalid lighting.";
      }
      return validateDecodedCameraImage(decoded);
    } catch (e) {
      debugPrint("⚠️ Gate 1 error reading image: $e");
      return "Camera obstructed or invalid lighting.";
    }
  }

  static String? validateDecodedCameraImage(img.Image decoded) {
    final grid = img.copyResize(decoded, width: 64, height: 64);
    const int totalPixels = 64 * 64;

    double sumLum = 0.0;
    double sumLumSq = 0.0;
    final List<List<double>> lumGrid = List.generate(64, (_) => List<double>.filled(64, 0.0));

    int validCoconutCenterPixels = 0;
    int totalCenterPixels = 0;

    int borderGreenPixels = 0;
    int totalBorderPixels = 0;

    // Center 60% ROI box on 64x64: [13 .. 50] inclusive (38x38 = 1444 pixels)
    const int roiStart = 13;
    const int roiEnd = 50;

    // Outer 15% border ring on 64x64: x < 10 or x >= 54 or y < 10 or y >= 54
    const int borderWidth = 10;

    double sumCenterHue = 0.0;
    double sumCenterHueSq = 0.0;

    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 64; x++) {
        final p = grid.getPixel(x, y);
        final double r = p.r / 255.0;
        final double g = p.g / 255.0;
        final double b = p.b / 255.0;

        final double lum = (0.299 * r + 0.587 * g + 0.114 * b) * 255.0;
        lumGrid[y][x] = lum;
        sumLum += lum;
        sumLumSq += lum * lum;

        final hsv = _rgbToHsv(r, g, b);
        final double hue = hsv[0];
        final double sat = hsv[1];
        final double val = hsv[2];

        // Green Coconut Husk HSV Check: Hue 32° to 158°, Saturation 0.14 to 0.92, Value 0.15 to 0.92
        final bool isGreenHuskPixel =
            (hue >= 32.0 && hue <= 158.0) &&
            (sat >= 0.14 && sat <= 0.92) &&
            (val >= 0.15 && val <= 0.92);

        // Center 60% ROI check
        if (x >= roiStart && x <= roiEnd && y >= roiStart && y <= roiEnd) {
          totalCenterPixels++;
          if (isGreenHuskPixel) {
            validCoconutCenterPixels++;
            sumCenterHue += hue;
            sumCenterHueSq += hue * hue;
          }
        }

        // Outer 15% border ring check
        if (x < borderWidth || x >= (64 - borderWidth) || y < borderWidth || y >= (64 - borderWidth)) {
          totalBorderPixels++;
          if (isGreenHuskPixel) {
            borderGreenPixels++;
          }
        }
      }
    }

    // 1. Black / Overexposed Check
    final double meanLuminance = sumLum / totalPixels;
    final double variance = math.max(0.0, (sumLumSq / totalPixels) - (meanLuminance * meanLuminance));
    final double stdDev = math.sqrt(variance);

    if (meanLuminance < 28.0 || meanLuminance > 242.0 || stdDev < 8.0) {
      debugPrint(
        "⛔ [GATE 1 - LUMINANCE] Rejected: meanLum=${meanLuminance.toStringAsFixed(1)}, stdDev=${stdDev.toStringAsFixed(1)}",
      );
      return "Camera obstructed or invalid lighting.";
    }

    // 2. Green Coconut Husk HSV Check (Center 60% ROI)
    final double centerGreenRatio = totalCenterPixels > 0 ? (validCoconutCenterPixels / totalCenterPixels) : 0.0;
    if (centerGreenRatio < 0.40) {
      debugPrint(
        "⛔ [GATE 1 - HSV HUSK] Rejected: centerGreenRatio=${(centerGreenRatio * 100).toStringAsFixed(1)}% (< 40%)",
      );
      return "No coconut detected. Center a green coconut in the frame.";
    }

    // Hue standard deviation among green center pixels (detects flat artificial solid color)
    double hueStdDev = 0.0;
    if (validCoconutCenterPixels > 10) {
      final double meanCenterHue = sumCenterHue / validCoconutCenterPixels;
      final double hueVar = math.max(0.0, (sumCenterHueSq / validCoconutCenterPixels) - (meanCenterHue * meanCenterHue));
      hueStdDev = math.sqrt(hueVar);
    }

    // 3. Grass, Foliage & Extreme Close-Up / Solid Green Overfill Check
    double sumEdgeDiff = 0.0;
    int edgeCount = 0;
    for (int y = roiStart; y < roiEnd; y++) {
      for (int x = roiStart; x < roiEnd; x++) {
        final double diffX = (lumGrid[y][x] - lumGrid[y][x + 1]).abs();
        final double diffY = (lumGrid[y][x] - lumGrid[y + 1][x]).abs();
        sumEdgeDiff += (diffX + diffY);
        edgeCount++;
      }
    }
    final double edgeRoughness = edgeCount > 0 ? (sumEdgeDiff / edgeCount) : 0.0;
    final double borderGreenRatio = totalBorderPixels > 0 ? (borderGreenPixels / totalBorderPixels) : 0.0;

    debugPrint(
      "📸 [GATE 1 PASS CHECK] meanLum=${meanLuminance.toStringAsFixed(1)}, stdDev=${stdDev.toStringAsFixed(1)}, "
      "centerGreen=${(centerGreenRatio * 100).toStringAsFixed(1)}%, "
      "borderGreen=${(borderGreenRatio * 100).toStringAsFixed(1)}%, "
      "edgeRoughness=${edgeRoughness.toStringAsFixed(1)}, "
      "hueStdDev=${hueStdDev.toStringAsFixed(1)}°",
    );

    // Check A: Extreme Close-Up or Solid Green Overfill (flooding outer border margins)
    if (borderGreenRatio > 0.78) {
      // If edgeRoughness is low or hue is unnaturally uniform, it's a solid green wall/paper or extreme close-up
      if (edgeRoughness < 18.0 || hueStdDev < 3.2) {
        debugPrint(
          "⛔ [GATE 1 - CLOSE-UP/SOLID GREEN] Rejected: borderGreen=${(borderGreenRatio * 100).toStringAsFixed(1)}%, "
          "edgeRoughness=${edgeRoughness.toStringAsFixed(1)}, hueStdDev=${hueStdDev.toStringAsFixed(1)}°",
        );
        return "Camera is too close or surface is a flat color. Step back so the whole coconut fits inside the circular guide.";
      }
      // If edgeRoughness is high, it's grass/foliage
      if (edgeRoughness > 24.0) {
        debugPrint(
          "⛔ [GATE 1 - FOLIAGE/GRASS] Rejected: borderGreen=${(borderGreenRatio * 100).toStringAsFixed(1)}%, edgeRoughness=${edgeRoughness.toStringAsFixed(1)}",
        );
        return "Background foliage/grass detected. Hold camera closer to a single coconut husk.";
      }
    }

    // Check B: Scattered grass or high-frequency weeds in background
    if (edgeRoughness > 30.0) {
      debugPrint("⛔ [GATE 1 - HIGH ROUGHNESS] Rejected: edgeRoughness=${edgeRoughness.toStringAsFixed(1)}");
      return "Background foliage/grass detected. Hold camera closer to a single coconut husk.";
    }

    // Check C: Flat synthetic solid surface even if centered (e.g. green paper/plastic)
    if (edgeRoughness < 5.0 && hueStdDev < 2.5) {
      debugPrint(
        "⛔ [GATE 1 - SYNTHETIC SOLID COLOR] Rejected: edgeRoughness=${edgeRoughness.toStringAsFixed(1)}, hueStdDev=${hueStdDev.toStringAsFixed(1)}°",
      );
      return "Flat solid color detected. Please point camera at a real coconut.";
    }

    return null; // Passed all Gate 1 checks!
  }

  /// Preprocesses a camera photo into an NCHW [1, 3, 224, 224] Float32List tensor
  Object? _preprocessImageForInterpreter(img.Image decoded, Interpreter interpreter) {
    try {
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

  /// Temperature-scaled normalization (T = 1.6) so hyper-confident 99.9% probabilities
  /// are calibrated to realistic field confidence levels and capped at 96.5%.
  List<double> _normalizeAndScaleProbs(List<double> raw, {double temperature = 1.6}) {
    double sum = raw.fold(0.0, (a, b) => a + b);
    List<double> logits;
    if ((sum - 1.0).abs() < 0.05 && raw.every((v) => v >= 0.0 && v <= 1.0)) {
      // Convert post-softmax probabilities back to log-space logits before temperature scaling
      logits = raw.map((p) => math.log(math.max(p, 1e-4))).toList();
    } else {
      logits = List<double>.from(raw);
    }

    final scaledLogits = logits.map((l) => l / temperature).toList();
    final double maxVal = scaledLogits.reduce((a, b) => a > b ? a : b);
    final List<double> exps = scaledLogits.map((v) => math.exp(v - maxVal)).toList();
    final double expSum = exps.fold(0.0, (a, b) => a + b);
    final List<double> probs = exps.map((e) => e / expSum).toList();

    // Also enforce hard cap at 96.5% (0.965)
    if (probs.length == 2) {
      if (probs[0] > 0.965) {
        return [0.965, 0.035];
      } else if (probs[1] > 0.965) {
        return [0.035, 0.965];
      }
    }
    return probs;
  }

  /// Runs Gate 1, Gate 2, and Gate 3 (70% Audio / 30% Visual Acoustic-Dominant Fusion)
  Future<PredictionResult> predict({
    required File imageFile,
    File? audioFile,
    double visualWeight = 0.30, // 30% Visual (Husk) / 70% Audio (Spectrogram)
    double confidenceThreshold = 0.65,
  }) async {
    if (!isLoaded) await loadModels();

    // --- GATE 1: CAMERA IMAGE PIXEL GATE ---
    final bytes = imageFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return PredictionResult(
        label: "Invalid Object",
        confidence: 0.0,
        classProbabilities: {"buko": 0.0, "malauhog": 0.0},
        visualLabel: "UNRECOGNIZED",
        visualConfidence: 0.0,
        audioLabel: "N/A",
        audioConfidence: 0.0,
        isValidObject: false,
        rejectionReason: "Camera obstructed or invalid lighting.",
      );
    }

    final String? gate1Error = validateDecodedCameraImage(decoded);
    if (gate1Error != null) {
      return PredictionResult(
        label: "Invalid Object",
        confidence: 0.0,
        classProbabilities: {"buko": 0.0, "malauhog": 0.0},
        visualLabel: "UNRECOGNIZED",
        visualConfidence: 0.0,
        audioLabel: "N/A",
        audioConfidence: 0.0,
        isValidObject: false,
        rejectionReason: gate1Error,
      );
    }

    final imgInput = _preprocessImageForInterpreter(decoded, _imgInterpreter!);
    if (imgInput == null) {
      return PredictionResult(
        label: "Invalid Object",
        confidence: 0.0,
        classProbabilities: {"buko": 0.0, "malauhog": 0.0},
        visualLabel: "UNRECOGNIZED",
        visualConfidence: 0.0,
        audioLabel: "N/A",
        audioConfidence: 0.0,
        isValidObject: false,
        rejectionReason: "Camera obstructed or invalid lighting.",
      );
    }

    final imgOutputShape = _imgInterpreter!.getOutputTensor(0).shape;
    final int numImgOutputs = imgOutputShape.reduce((a, b) => a * b);
    var imgOutput = List.filled(numImgOutputs, 0.0).reshape(imgOutputShape);
    _imgInterpreter!.run(imgInput, imgOutput);

    List<double> rawImgProbs = List<double>.from(imgOutputShape.length == 2 ? imgOutput[0] : imgOutput);
    List<double> imgProbs = _normalizeAndScaleProbs(rawImgProbs, temperature: 1.6);

    String visualLabel = imgProbs[0] >= imgProbs[1] ? "buko" : "malauhog";
    double visualConf = math.max(imgProbs[0], imgProbs[1]);

    // --- GATE 2: MEL-SPECTROGRAM STRIPE COUNTER & AUDIO INFERENCE ---
    List<double> specProbs;
    String audioLabel = "N/A";
    double audioConf = 0.0;

    if (audioFile != null && await audioFile.exists()) {
      try {
        debugPrint("🎵 Generating Dart Mel-Spectrogram & running Gate 2 for: ${audioFile.path}");
        final specInput = SpectrogramService.generateSpectrogramTensor(audioFile);

        final specOutputShape = _specInterpreter!.getOutputTensor(0).shape;
        final int numSpecOutputs = specOutputShape.reduce((a, b) => a * b);
        var specOutput = List.filled(numSpecOutputs, 0.0).reshape(specOutputShape);
        _specInterpreter!.run(specInput, specOutput);

        List<double> rawSpecProbs = List<double>.from(specOutputShape.length == 2 ? specOutput[0] : specOutput);
        specProbs = _normalizeAndScaleProbs(rawSpecProbs, temperature: 1.6);

        audioLabel = specProbs[0] >= specProbs[1] ? "buko" : "malauhog";
        audioConf = math.max(specProbs[0], specProbs[1]);
        debugPrint("🎵 Real Audio Prediction: $audioLabel (${(audioConf * 100).toStringAsFixed(1)}%)");
      } on SpectrogramValidationException catch (specErr) {
        debugPrint("⛔ [GATE 2 REJECTED] ${specErr.message}");
        return PredictionResult(
          label: "Invalid Object",
          confidence: 0.0,
          classProbabilities: {"buko": 0.0, "malauhog": 0.0},
          visualLabel: visualLabel,
          visualConfidence: visualConf,
          audioLabel: "INVALID TAP",
          audioConfidence: 0.0,
          isValidObject: false,
          rejectionReason: specErr.message,
        );
      } catch (e) {
        debugPrint("⛔ [GATE 2 ERROR] $e");
        return PredictionResult(
          label: "Invalid Object",
          confidence: 0.0,
          classProbabilities: {"buko": 0.0, "malauhog": 0.0},
          visualLabel: visualLabel,
          visualConfidence: visualConf,
          audioLabel: "INVALID TAP",
          audioConfidence: 0.0,
          isValidObject: false,
          rejectionReason: "No acoustic tap detected in spectrogram. Knock the coconut shoulder 3 times.",
        );
      }
    } else {
      specProbs = List.from(imgProbs);
      audioLabel = "N/A (Skipped)";
      audioConf = visualConf;
    }

    // --- 70% AUDIO / 30% VISUAL LATE FUSION & GATE 3 (ACOUSTIC-DOMINANT VETO) ---
    final double audioWeight = 1.0 - visualWeight; // 0.70
    double bukoProb = (visualWeight * imgProbs[0]) + (audioWeight * specProbs[0]);
    double malauhogProb = (visualWeight * imgProbs[1]) + (audioWeight * specProbs[1]);

    String finalLabel = bukoProb >= malauhogProb ? "buko" : "malauhog";
    double highestConfidence = math.min(0.965, math.max(bukoProb, malauhogProb));

    debugPrint(
      "🎯 [70/30 FUSION] Visual(30%)=$visualLabel(${(visualConf * 100).toStringAsFixed(1)}%), "
      "Audio(70%)=$audioLabel(${(audioConf * 100).toStringAsFixed(1)}%) -> "
      "Fused=$finalLabel(${(highestConfidence * 100).toStringAsFixed(1)}%)",
    );

    if (audioFile != null && audioLabel != "N/A (Skipped)") {
      // Require minimum individual confidence floor (0.65) on the dominant audio model
      if (audioConf < 0.65) {
        return PredictionResult(
          label: "Invalid Object",
          confidence: 0.0,
          classProbabilities: {"buko": 0.0, "malauhog": 0.0},
          visualLabel: visualLabel,
          visualConfidence: visualConf,
          audioLabel: audioLabel,
          audioConfidence: audioConf,
          isValidObject: false,
          rejectionReason: "Inconclusive Scan: Acoustic signal confidence too low. Please knock 3 times clearly.",
        );
      }

      // If Visual and Audio disagree:
      // Allow 70% Audio to override ambiguous outer husk ONLY if Audio is decisive (>= 0.75) and Fused >= 0.65.
      // Otherwise reject as Inconclusive Scan.
      if (visualLabel != audioLabel && (audioConf < 0.75 || highestConfidence < confidenceThreshold)) {
        debugPrint(
          "⛔ [GATE 3 - VETO] Visual ($visualLabel) != Audio ($audioLabel) and AudioConf (${(audioConf * 100).toStringAsFixed(1)}%) < 75%",
        );
        return PredictionResult(
          label: "Invalid Object",
          confidence: 0.0,
          classProbabilities: {"buko": 0.0, "malauhog": 0.0},
          visualLabel: visualLabel,
          visualConfidence: visualConf,
          audioLabel: audioLabel,
          audioConfidence: audioConf,
          isValidObject: false,
          rejectionReason: "Inconclusive Scan: Visual and audio readings disagree. Please rescan.",
        );
      }
    } else {
      // Photo-only mode requires visualConfidence >= 0.65
      if (visualConf < 0.65) {
        return PredictionResult(
          label: "Invalid Object",
          confidence: 0.0,
          classProbabilities: {"buko": 0.0, "malauhog": 0.0},
          visualLabel: visualLabel,
          visualConfidence: visualConf,
          audioLabel: audioLabel,
          audioConfidence: audioConf,
          isValidObject: false,
          rejectionReason: "No coconut detected. Center a green coconut in the frame.",
        );
      }
    }

    return PredictionResult(
      label: finalLabel,
      confidence: highestConfidence,
      classProbabilities: {
        "buko": bukoProb,
        "malauhog": malauhogProb,
      },
      visualLabel: visualLabel,
      visualConfidence: visualConf,
      audioLabel: audioLabel,
      audioConfidence: audioConf,
      isValidObject: true,
      rejectionReason: null,
    );
  }

  void dispose() {
    _imgInterpreter?.close();
    _specInterpreter?.close();
  }
}