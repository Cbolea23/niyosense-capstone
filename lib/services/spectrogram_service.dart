import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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

  /// Reads raw 16-bit PCM audio samples from a WAV file and pads/trims to 88,200 samples
  static Float32List _readAndFixWavAudio(File wavFile) {
    final bytes = wavFile.readAsBytesSync();
    if (bytes.length < 44) {
      throw Exception("Invalid WAV file: size too small.");
    }

    // Locate the 'data' subchunk inside the WAV file header
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
      dataIndex = 44; // Standard WAV header fallback
    }

    if (dataIndex >= bytes.length) {
      return Float32List(targetSamples);
    }

    final byteData = ByteData.sublistView(bytes, dataIndex);
    final int availableSamples = byteData.lengthInBytes ~/ 2;
    final int samplesToRead = math.min(availableSamples, targetSamples);

    final pcmSamples = Float32List(targetSamples);
    for (int i = 0; i < samplesToRead; i++) {
      pcmSamples[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
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

  /// Generates the exact [1, 3, 224, 224] Float32 tensor matching Librosa + Magma
  static Object generateSpectrogramTensor(File wavFile) {
    final samples = _readAndFixWavAudio(wavFile);

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

    // Top-dB clipping floor (-80 dB below peak)
    const double topDb = 80.0;

    for (int m = 0; m < nMels; m++) {
      for (int f = 0; f < numFrames; f++) {
        sDb[m][f] = math.max(sDb[m][f] - maxVal, -topDb);
      }
    }

    // 6. Rescale to [0.0, 1.0], apply 'magma' colormap, and resize to 224x224 (NCHW)
    final tensorBuffer = Float32List(1 * 3 * targetHeight * targetWidth);
    const int channelSize = targetHeight * targetWidth;

    for (int y = 0; y < targetHeight; y++) {
      // In specshow, row 0 (top of image) is highest frequency (mel 127)
      final double melPos = (1.0 - (y / (targetHeight - 1))) * (nMels - 1);
      final int m0 = melPos.floor().clamp(0, nMels - 2);
      final double mRatio = melPos - m0;

      for (int x = 0; x < targetWidth; x++) {
        final double framePos = (x / (targetWidth - 1)) * (numFrames - 1);
        final int f0 = framePos.floor().clamp(0, numFrames - 2);
        final double fRatio = framePos - f0;

        // Bilinear interpolation of dB value
        final double v00 = sDb[m0][f0];
        final double v10 = sDb[m0 + 1][f0];
        final double v01 = sDb[m0][f0 + 1];
        final double v11 = sDb[m0 + 1][f0 + 1];

        final double interpDb = (1 - mRatio) * ((1 - fRatio) * v00 + fRatio * v01) +
            mRatio * ((1 - fRatio) * v10 + fRatio * v11);

        // Normalize [-80, 0] dB to [0.0, 1.0]
        final double normalized = (interpDb + topDb) / topDb;
        final rgb = _magma(normalized);

        final int pixelIndex = y * targetWidth + x;
        tensorBuffer[0 * channelSize + pixelIndex] = rgb[0]; // Red channel
        tensorBuffer[1 * channelSize + pixelIndex] = rgb[1]; // Green channel
        tensorBuffer[2 * channelSize + pixelIndex] = rgb[2]; // Blue channel
      }
    }

    return tensorBuffer.reshape([1, 3, targetHeight, targetWidth]);
  }
}