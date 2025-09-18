import 'package:english_speech/extension/list_extension.dart';
import 'package:english_speech/google/gemini_tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('get speech audio', () {
    test('should return a non-empty audio string', () async {
      final voice = predifinedVoiceNames.randomItem;
      final result = await getSpeechAudio(contents1, voice);
      expect(result, isNotEmpty);
    });
  });
}

const contents1 = [
  'It has the distinct appearance of traditional cel animation.',
  'The colors are somewhat muted and consistent.',
];
