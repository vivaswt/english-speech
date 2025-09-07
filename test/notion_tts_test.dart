import 'package:english_speech/notion_contents_for_tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('post records', () {
    test('normal regist', () async {
      final result = await registForTTS(
        title: 'My first test',
        url: 'https://www.gamesradar.com/',
        content: content1,
      );
      expect(result, isNotEmpty);
    });
  });
}

final List<String> content1 =
    '''
Former Nintendo software developer Ken Watanabe, not to be confused with one of the most famous Japanese actors of all time, says his ex-employer doesn't create entirely new franchises all too often simply because it doesn't need to.
From Watanabe's perspective, Nintendo already has plenty of beloved IP to use essentially as templates for creating new and exciting gameplay experiences.
'''
        .split('\n');
