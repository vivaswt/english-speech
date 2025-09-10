import 'package:english_speech/notion_web_articles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('mark as processed', () {
    test('normal test', () async {
      final result = await markArticleAsProcessed(
        '26aca48a865381aca845e88691c473b3',
      );
      expect(result, isNotEmpty);
    });
  });
}
