import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:niyosense_mobile/services/spectrogram_service.dart';

Uint8List createWavFile({
  required int sampleRate,
  required int durationSeconds,
  required List<double> tapTimes,
}) {
  final int totalSamples = sampleRate * durationSeconds;
  final samples = Float32List(totalSamples);

  // Add 3 resonant knuckle knocks (around 500-800 Hz with exponential decay)
  for (final tapTime in tapTimes) {
    final int startSample = (tapTime * sampleRate).toInt();
    final int tapLength = (sampleRate * 0.12).toInt(); // 120ms tap decay
    for (int i = 0; i < tapLength && (startSample + i) < totalSamples; i++) {
      final double t = i / sampleRate;
      final double env = math.exp(-t * 35.0); // decaying envelope
      final double osc = math.sin(2.0 * math.pi * 650.0 * t); // 650 Hz resonance
      samples[startSample + i] += (osc * env * 0.4).toDouble();
    }
  }

  // Create 16-bit PCM WAV bytes
  final int byteLength = totalSamples * 2;
  final wavData = ByteData(44 + byteLength);

  // RIFF header
  wavData.setUint8(0, 0x52); // 'R'
  wavData.setUint8(1, 0x49); // 'I'
  wavData.setUint8(2, 0x46); // 'F'
  wavData.setUint8(3, 0x46); // 'F'
  wavData.setUint32(4, 36 + byteLength, Endian.little);
  wavData.setUint8(8, 0x57);  // 'W'
  wavData.setUint8(9, 0x41);  // 'A'
  wavData.setUint8(10, 0x56); // 'V'
  wavData.setUint8(11, 0x45); // 'E'

  // fmt chunk
  wavData.setUint8(12, 0x66); // 'f'
  wavData.setUint8(13, 0x6d); // 'm'
  wavData.setUint8(14, 0x74); // 't'
  wavData.setUint8(15, 0x20); // ' '
  wavData.setUint32(16, 16, Endian.little); // chunk size
  wavData.setUint16(20, 1, Endian.little);  // PCM format
  wavData.setUint16(22, 1, Endian.little);  // 1 channel (Mono)
  wavData.setUint32(24, sampleRate, Endian.little);
  wavData.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  wavData.setUint16(32, 2, Endian.little);  // block align
  wavData.setUint16(34, 16, Endian.little); // bits per sample

  // data chunk
  wavData.setUint8(36, 0x64); // 'd'
  wavData.setUint8(37, 0x61); // 'a'
  wavData.setUint8(38, 0x74); // 't'
  wavData.setUint8(39, 0x61); // 'a'
  wavData.setUint32(40, byteLength, Endian.little);

  for (int i = 0; i < totalSamples; i++) {
    final int pcm = (samples[i].clamp(-1.0, 1.0) * 32767.0).round();
    wavData.setInt16(44 + i * 2, pcm, Endian.little);
  }

  return wavData.buffer.asUint8List();
}

void main() {
  test('SpectrogramService stripe detection on 3 taps', () {
    final wavBytes = createWavFile(
      sampleRate: 44100,
      durationSeconds: 4,
      tapTimes: [1.0, 2.0, 3.0],
    );

    final tmpFile = File('test_tap.wav');
    tmpFile.writeAsBytesSync(wavBytes);

    try {
      final tensor = SpectrogramService.generateSpectrogramTensor(tmpFile);
      expect(tensor, isNotNull);
    } finally {
      if (tmpFile.existsSync()) tmpFile.deleteSync();
    }
  });
}
