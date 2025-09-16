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

  final Iterable<Wav> wavs = base64EncodedStrings
      .map(base64.decode)
      .map(Wav.read);

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
