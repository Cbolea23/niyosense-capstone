import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class SpectrogramValidationException implements Exception {
  final String message;
  final int stripeCount;
  SpectrogramValidationException(this.message, {this.stripeCount = 0});

  @override
  String toString() => message;
}

class SpectrogramService {
  static const int sampleRate = 22050;
  static const int targetSamples = sampleRate * 4; // 88,200 samples (4.0s)
  static const int nFft = 2048;
  static const int hopLength = 512;
  static const int nMels = 128;
  static const int targetHeight = 224;
  static const int targetWidth = 224;

  /// Control points for Matplotlib's 'magma' colormap
  static const List<List<double>> _magmaPoints = [
    [0.000, 0.001, 0.001, 0.014], // #000004
    [0.125, 0.111, 0.064, 0.266], // #1c1044
    [0.250, 0.311, 0.071, 0.484], // #4f127b
    [0.375, 0.511, 0.147, 0.505], // #82257f
    [0.500, 0.713, 0.213, 0.476], // #b6367a
    [0.625, 0.899, 0.350, 0.392], // #e55964
    [0.750, 0.985, 0.535, 0.382], // #fb8861
    [0.875, 0.996, 0.765, 0.545], // #fec38b
    [1.000, 0.987, 0.991, 0.749], // #fcfdbf
  ];

  /// Interpolates RGB values from the Magma colormap (normalized 0.0 to 1.0)
  static List<double> _magma(double t) {
    final clamped = t.clamp(0.0, 1.0);
    for (int i = 0; i < _magmaPoints.length - 1; i++) {
      final p1 = _magmaPoints[i];
      final p2 = _magmaPoints[i + 1];
      if (clamped >= p1[0] && clamped <= p2[0]) {
        final ratio = (clamped - p1[0]) / (p2[0] - p1[0]);
        return [
          p1[1] + ratio * (p2[1] - p1[1]),
          p1[2] + ratio * (p2[2] - p1[2]),
          p1[3] + ratio * (p2[3] - p1[3]),
        ];
      }
    }
    return [0.987, 0.991, 0.749];
  }

  /// Converts frequency in Hz to Mel scale
  static double _hzToMel(double hz) => 2595.0 * (math.log(1.0 + hz / 700.0) / math.ln10);

  /// Converts Mel scale to frequency in Hz
  static double _melToHz(double mel) => 700.0 * (math.pow(10.0, mel / 2595.0) - 1.0);

  /// Generates the 128 Mel triangular filterbank matrix
  static List<Float32List> _createMelFilterbank() {
    final int numBins = nFft ~/ 2 + 1; // 1025
    final double minMel = _hzToMel(0.0);
    final double maxMel = _hzToMel(sampleRate / 2.0); // 11025 Hz

    final melPoints = List<double>.generate(
      nMels + 2,
      (i) => minMel + i * (maxMel - minMel) / (nMels + 1),
    );
    final hzPoints = melPoints.map(_melToHz).toList();
    final binPoints = hzPoints.map((hz) => (hz * nFft / sampleRate).round()).toList();

    final filterbank = List<Float32List>.generate(nMels, (_) => Float32List(numBins));

    for (int m = 0; m < nMels; m++) {
      final left = binPoints[m];
      final center = binPoints[m + 1];
      final right = binPoints[m + 2];

      for (int k = left; k < center; k++) {
        if (k < numBins && center > left) {
          filterbank[m][k] = (k - left) / (center - left);
        }
      }
      for (int k = center; k < right; k++) {
        if (k < numBins && right > center) {
          filterbank[m][k] = (right - k) / (right - center);
        }
      }
    }
    return filterbank;
  }

  /// Reads raw 16-bit PCM audio samples from a WAV file, detects native sample rate and channels,
  /// downmixes stereo to mono if needed, resamples to exactly 22,050 Hz, and pads/trims to target 88,200 samples
  static Float32List _readAndFixWavAudio(File wavFile) {
    final bytes = wavFile.readAsBytesSync();
    if (bytes.length < 44) {
      throw SpectrogramValidationException("No acoustic tap detected in spectrogram. Knock the coconut shoulder 3 times.");
    }

    int fileSampleRate = 44100;
    int channels = 1;
    try {
      final headerData = ByteData.sublistView(bytes, 0, 44);
      channels = headerData.getUint16(22, Endian.little);
      fileSampleRate = headerData.getUint32(24, Endian.little);
      debugPrint("🎵 [AUDIO SPEC] Detected WAV: $fileSampleRate Hz, $channels channel(s)");
    } catch (_) {
      fileSampleRate = 44100;
      channels = 1;
    }

    int dataIndex = 36;
    for (int i = 12; i < bytes.length - 4; i++) {
      if (bytes[i] == 0x64 &&
          bytes[i + 1] == 0x61 &&
          bytes[i + 2] == 0x74 &&
          bytes[i + 3] == 0x61) {
        dataIndex = i + 8;
        break;
      }
    }

    if (dataIndex >= bytes.length) {
      dataIndex = 44;
    }

    if (dataIndex >= bytes.length) {
      return Float32List(targetSamples);
    }

    final byteData = ByteData.sublistView(bytes, dataIndex);
    final int rawSampleCount = byteData.lengthInBytes ~/ 2;
    if (rawSampleCount == 0) {
      return Float32List(targetSamples);
    }

    // Convert raw 16-bit PCM to normalized float [-1.0 .. 1.0] and mixdown to mono
    Float32List monoSamples;
    if (channels == 2) {
      final int numFrames = rawSampleCount ~/ 2;
      monoSamples = Float32List(numFrames);
      for (int i = 0; i < numFrames; i++) {
        final double left = byteData.getInt16(i * 4, Endian.little) / 32768.0;
        final double right = byteData.getInt16(i * 4 + 2, Endian.little) / 32768.0;
        monoSamples[i] = (left + right) / 2.0;
      }
    } else {
      monoSamples = Float32List(rawSampleCount);
      for (int i = 0; i < rawSampleCount; i++) {
        monoSamples[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      }
    }

    final pcmSamples = Float32List(targetSamples);

    // Resample monoSamples to exactly 22,050 Hz (88,200 samples for 4.0s)
    if (fileSampleRate <= 0) fileSampleRate = 44100;
    final double resampleRatio = fileSampleRate / sampleRate;

    final int samplesToGenerate = math.min(
      targetSamples,
      (monoSamples.length / resampleRatio).floor(),
    );

    for (int i = 0; i < samplesToGenerate; i++) {
      final double srcPos = i * resampleRatio;
      final int srcIdx = srcPos.floor();
      final double frac = srcPos - srcIdx;

      if (srcIdx + 1 < monoSamples.length) {
        pcmSamples[i] = (1.0 - frac) * monoSamples[srcIdx] + frac * monoSamples[srcIdx + 1];
      } else if (srcIdx < monoSamples.length) {
        pcmSamples[i] = monoSamples[srcIdx];
      }
    }

    return pcmSamples;
  }

  /// Fast Fourier Transform (Radix-2 In-Place Cooley-Tukey)
  static void _fft(Float32List real, Float32List imag) {
    final int n = real.length;
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;
        final ti = imag[i];
        imag[i] = imag[j];
        imag[j] = ti;
      }
      int k = n ~/ 2;
      while (k <= j) {
        j -= k;
        k ~/= 2;
      }
      j += k;
    }

    for (int len = 2; len <= n; len <<= 1) {
      final double angle = -2.0 * math.pi / len;
      final double wlenR = math.cos(angle);
      final double wlenI = math.sin(angle);

      for (int i = 0; i < n; i += len) {
        double wR = 1.0;
        double wI = 0.0;
        for (int k = 0; k < len ~/ 2; k++) {
          final int u = i + k;
          final int v = i + k + len ~/ 2;
          final double tr = wR * real[v] - wI * imag[v];
          final double ti = wR * imag[v] + wI * real[v];
          real[v] = real[u] - tr;
          imag[v] = imag[u] - ti;
          real[u] += tr;
          imag[u] += ti;

          final double nextWR = wR * wlenR - wI * wlenI;
          wI = wR * wlenI + wI * wlenR;
          wR = nextWR;
        }
      }
    }
  }

  /// GATE 2: MEL-SPECTROGRAM IMAGE STRIPE COUNTER (100% Phone-Microphone Independent)
  /// Downsamples generated spectrogram image to 64x64 grid, inspects resonance rows (y = 10..60),
  /// computes colEnergy[x] (0-255), medianColEnergy, and counts distinct vertical bright stripes
  /// where colEnergy[x] > max(medianColEnergy + 12, 22), separated by >= 2 dark columns.
  static int validateSpectrogramStripes(img.Image specImage) {
    final grid = img.copyResize(specImage, width: 64, height: 64);
    // Rows 10 to 60 capture the acoustic percussion spectrum (~120 Hz to 7,500 Hz),
    // excluding DC sub-bass microphone offset (rows 61..63) and ultra-high hiss (rows 0..9).
    const int startRow = 10;
    const int endRow = 60;
    const int numRows = endRow - startRow + 1;

    final List<double> colEnergy = List<double>.filled(64, 0.0);
    for (int x = 0; x < 64; x++) {
      double sumBrightness = 0.0;
      for (int y = startRow; y <= endRow; y++) {
        final p = grid.getPixel(x, y);
        // Perceived pixel brightness on 0-255 scale (dark purple/black is low, orange/yellow is high)
        final double brightness = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        sumBrightness += brightness;
      }
      colEnergy[x] = sumBrightness / numRows;
    }

    final List<double> sortedEnergy = List<double>.from(colEnergy)..sort();
    final double medianColEnergy = (sortedEnergy[31] + sortedEnergy[32]) / 2.0;
    final double peakThreshold = math.max(medianColEnergy + 12.0, 22.0);

    // Count distinct vertical bright stripes separated by at least 2 dark columns (~125ms)
    int stripeCount = 0;
    int darkColumnsSinceLastStripe = 999; // Allow first stripe immediately

    for (int x = 0; x < 64; x++) {
      final bool isBright = colEnergy[x] > peakThreshold;
      if (isBright) {
        if (darkColumnsSinceLastStripe >= 2) {
          stripeCount++;
        }
        darkColumnsSinceLastStripe = 0;
      } else {
        darkColumnsSinceLastStripe++;
      }
    }

    debugPrint(
      "🎵 [GATE 2 - STRIPE COUNTER] MedianEnergy=${medianColEnergy.toStringAsFixed(1)}, "
      "Threshold=${peakThreshold.toStringAsFixed(1)}, DetectedStripes=$stripeCount",
    );

    if (stripeCount < 1) {
      throw SpectrogramValidationException(
        "No acoustic tap detected in spectrogram. Knock the coconut shoulder 3 times.",
        stripeCount: stripeCount,
      );
    }
    if (stripeCount > 6) {
      throw SpectrogramValidationException(
        "Too many rapid taps or noise spikes detected ($stripeCount spikes). Knock strictly 3 times.",
        stripeCount: stripeCount,
      );
    }

    return stripeCount;
  }

  /// Generates the exact [1, 3, 224, 224] Float32 tensor matching Librosa + Magma
  /// and runs Gate 2 (Mel-Spectrogram Image Stripe Counter) before returning.
  static Object generateSpectrogramTensor(File wavFile) {
    final samples = _readAndFixWavAudio(wavFile);

    // Remove DC offset so mic hardware bias does not skew low-frequency bins or peak detection
    double sumSample = 0.0;
    for (int i = 0; i < samples.length; i++) {
      sumSample += samples[i];
    }
    final double dcOffset = sumSample / samples.length;

    // Raw silence floor check (prevents amplifying pure digital zeros into white noise)
    double peakAmp = 0.0;
    for (int i = 0; i < samples.length; i++) {
      final double centered = samples[i] - dcOffset;
      samples[i] = centered;
      final double val = centered.abs();
      if (val > peakAmp) peakAmp = val;
    }
    if (peakAmp < 0.005) {
      throw SpectrogramValidationException(
        "No acoustic tap detected in spectrogram. Knock the coconut shoulder 3 times.",
        stripeCount: 0,
      );
    }

    // Normalize peak amplitude to 0.95 full scale (bounded at 25x max boost) so phones with raw
    // UNPROCESSED ADC levels (e.g. Samsung S25+ with peak ~0.12) never clip against the 1e-10 STFT floor.
    final double normGain = (0.95 / peakAmp).clamp(1.0, 25.0);
    if (normGain > 1.01) {
      for (int i = 0; i < samples.length; i++) {
        samples[i] = (samples[i] * normGain).clamp(-1.0, 1.0);
      }
      debugPrint(
        "🎵 [AUDIO SPEC] Peak=${peakAmp.toStringAsFixed(4)}, applied ${normGain.toStringAsFixed(2)}x gain normalization",
      );
    }

    // 1. Center-reflect pad audio with nFft // 2 = 1024 samples on both sides
    const int pad = nFft ~/ 2;
    final paddedSamples = Float32List(samples.length + 2 * pad);
    for (int i = 0; i < pad; i++) {
      paddedSamples[pad - 1 - i] = samples[i + 1];
      paddedSamples[pad + samples.length + i] = samples[samples.length - 2 - i];
    }
    paddedSamples.setRange(pad, pad + samples.length, samples);

    // 2. Compute Periodic Hann Window
    final hann = Float32List(nFft);
    for (int i = 0; i < nFft; i++) {
      hann[i] = 0.5 - 0.5 * math.cos(2.0 * math.pi * i / nFft);
    }

    // 3. Compute STFT Power Spectrogram
    final int numFrames = 1 + (paddedSamples.length - nFft) ~/ hopLength;
    final int numBins = nFft ~/ 2 + 1; // 1025
    final powerSpec = List<Float32List>.generate(numFrames, (_) => Float32List(numBins));

    final real = Float32List(nFft);
    final imag = Float32List(nFft);

    for (int frame = 0; frame < numFrames; frame++) {
      final int start = frame * hopLength;
      for (int i = 0; i < nFft; i++) {
        real[i] = paddedSamples[start + i] * hann[i];
        imag[i] = 0.0;
      }
      _fft(real, imag);

      for (int bin = 0; bin < numBins; bin++) {
        powerSpec[frame][bin] = real[bin] * real[bin] + imag[bin] * imag[bin];
      }
    }

    // 4. Apply 128 Mel Filterbank
    final melFilterbank = _createMelFilterbank();
    final melSpectrogram = List<Float32List>.generate(nMels, (_) => Float32List(numFrames));

    for (int m = 0; m < nMels; m++) {
      final filter = melFilterbank[m];
      for (int frame = 0; frame < numFrames; frame++) {
        double sum = 0.0;
        final framePower = powerSpec[frame];
        for (int bin = 0; bin < numBins; bin++) {
          final w = filter[bin];
          if (w > 0.0) sum += w * framePower[bin];
        }
        melSpectrogram[m][frame] = sum;
      }
    }

    // 5. Convert to Decibels: S_dB = 10 * log10(max(S, 1e-10)), ref = max
    double maxVal = -1e9;
    final sDb = List<Float32List>.generate(nMels, (_) => Float32List(numFrames));

    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < numFrames; f++) {
        final val = 10.0 * (math.log(math.max(melSpectrogram[m][f], 1e-10)) / math.ln10);
        sDb[m][f] = val;
        if (val > maxVal) maxVal = val;
      }
    }

    const double topDb = 80.0;
    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < numFrames; f++) {
        sDb[m][f] = math.max(sDb[m][f] - maxVal, -topDb);
      }
    }

    // 6. Rescale to [0.0, 1.0], apply 'magma' colormap, and resize to 224x224 (NCHW)
    final tensorBuffer = Float32List(1 * 3 * targetHeight * targetWidth);
    const int channelSize = targetHeight * targetWidth;

    final img.Image debugImg = img.Image(width: targetWidth, height: targetHeight);

    for (int y = 0; y < targetHeight; y++) {
      final double melPos = (1.0 - (y / (targetHeight - 1))) * (nMels - 1);
      final int m0 = melPos.floor().clamp(0, nMels - 2);
      final double mRatio = melPos - m0;

      for (int x = 0; x < targetWidth; x++) {
        final double framePos = (x / (targetWidth - 1)) * (numFrames - 1);
        final int f0 = framePos.floor().clamp(0, numFrames - 2);
        final double fRatio = framePos - f0;

        final double v00 = sDb[m0][f0];
        final double v10 = sDb[m0 + 1][f0];
        final double v01 = sDb[m0][f0 + 1];
        final double v11 = sDb[m0 + 1][f0 + 1];

        final double interpDb = (1 - mRatio) * ((1 - fRatio) * v00 + fRatio * v01) +
            mRatio * ((1 - fRatio) * v10 + fRatio * v11);

        final double normalized = (interpDb + topDb) / topDb;
        final rgb = _magma(normalized);

        final int pixelIndex = y * targetWidth + x;
        tensorBuffer[0 * channelSize + pixelIndex] = rgb[0];
        tensorBuffer[1 * channelSize + pixelIndex] = rgb[1];
        tensorBuffer[2 * channelSize + pixelIndex] = rgb[2];

        debugImg.setPixelRgb(
          x,
          y,
          (rgb[0] * 255).round().clamp(0, 255),
          (rgb[1] * 255).round().clamp(0, 255),
          (rgb[2] * 255).round().clamp(0, 255),
        );
      }
    }

    // Save PNG alongside audio file for inspection
    try {
      final pngPath = wavFile.path.replaceAll(RegExp(r'\.wav$', caseSensitive: false), '_spectrogram.png');
      final pngBytes = img.encodePng(debugImg);
      File(pngPath).writeAsBytesSync(pngBytes);
      debugPrint("📸 [TEST A] Saved generated Spectrogram PNG to: $pngPath (${pngBytes.length} bytes)");
    } catch (e) {
      debugPrint("⚠️ Could not write debug spectrogram PNG: $e");
    }

    // 7. Run Gate 2: Mel-Spectrogram Image Stripe Counter on the 224x224 Magma image
    validateSpectrogramStripes(debugImg);

    return tensorBuffer.reshape([1, 3, targetHeight, targetWidth]);
  }
}