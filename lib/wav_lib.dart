import 'dart:convert';
import 'dart:typed_data';

import 'package:wav/wav.dart';

/// Decodes and joins multiple base64-encoded WAV audio strings into a single WAV object.
///
/// It assumes all input WAVs have the same number of channels and sample rate.
Wav joinWavsFromBase64(Iterable<String> base64EncodedStrings) {
  if (base64EncodedStrings.isEmpty) {
    throw ArgumentError('Input cannot be empty.');
  }

  final List<Wav> wavs = base64EncodedStrings
      .map(base64.decode)
      // .map(
      //   (pcm) =>
      //       pcmToWav(pcm, sampleRate: 24000, numChannels: 1, bitsPerSample: 16),
      // )
      .map(Wav.read)
      .toList();

  final List<Float64List> initChannels = List.generate(
    wavs.first.channels.length,
    (_) => Float64List(0),
  );

  Float64List add(Float64List ls1, Float64List ls2) =>
      Float64List.fromList([...ls1, ...ls2]);

  final List<Float64List> channels = wavs.fold(
    initChannels,
    (cs, wav) => List<Float64List>.generate(
      cs.length,
      (i) => add(cs[i], wav.channels[i]),
    ),
  );

  final samplePerSecond = wavs.first.samplesPerSecond;
  return Wav(channels, samplePerSecond);
}

/// Converts PCM (signed 16-bit little endian) into WAV byte file.
///
/// [pcm]: raw PCM data bytes
/// [sampleRate]: e.g. 24000
/// [numChannels]: 1 or more
/// [bitsPerSample]: usually 16 for Gemini LINEAR16
Uint8List pcmToWav(
  Uint8List pcm, {
  required int sampleRate,
  required int numChannels,
  required int bitsPerSample,
}) {
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataLength = pcm.length;
  final wavHeader = BytesBuilder();

  // RIFF header
  wavHeader.add(ascii.encode('RIFF'));
  // file size minus 8 bytes for RIFF and WAVE headers
  wavHeader.add(_intToBytes(36 + dataLength, 4, littleEndian: true));
  wavHeader.add(ascii.encode('WAVE'));

  // fmt subchunk
  wavHeader.add(ascii.encode('fmt '));
  wavHeader.add(
    _intToBytes(16, 4, littleEndian: true),
  ); // Subchunk1Size (16 for PCM)
  wavHeader.add(_intToBytes(1, 2, littleEndian: true)); // AudioFormat (1 = PCM)
  wavHeader.add(_intToBytes(numChannels, 2, littleEndian: true));
  wavHeader.add(_intToBytes(sampleRate, 4, littleEndian: true));
  wavHeader.add(_intToBytes(byteRate, 4, littleEndian: true));
  wavHeader.add(_intToBytes(blockAlign, 2, littleEndian: true));
  wavHeader.add(_intToBytes(bitsPerSample, 2, littleEndian: true));

  // data subchunk
  wavHeader.add(ascii.encode('data'));
  wavHeader.add(_intToBytes(dataLength, 4, littleEndian: true));

  // Then PCM data
  wavHeader.add(pcm);

  return wavHeader.toBytes();
}

/// Convert integer to little-endian or big-endian byte list
List<int> _intToBytes(int value, int byteCount, {bool littleEndian = false}) {
  final result = List<int>.filled(byteCount, 0);
  for (int i = 0; i < byteCount; i++) {
    final shift = littleEndian ? (8 * i) : (8 * (byteCount - 1 - i));
    result[i] = (value >> shift) & 0xFF;
  }
  return result;
}
