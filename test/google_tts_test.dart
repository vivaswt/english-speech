import 'package:english_speech/google/google_tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('get voices list', () {
    test('should return a non-empty list', () async {
      final result = await getVoicesList();
      expect(result, isNotEmpty);
    });
  });
}
