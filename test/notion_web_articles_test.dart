import 'package:english_speech/notion/notion_web_articles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;

void main() {
  group('mark as processed', () {
    // This is an integration test that makes a real API call to Notion.
    // It requires the NOTION_API_KEY environment variable to be set.
    // Example: NOTION_API_KEY="your_key" flutter test --tags integration
    test('should successfully mark an article as processed', () async {
      // Arrange: Check for the API key and skip if not present.
      final apiKey = Platform.environment['NOTION_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        markTestSkipped(
          'Skipping test: NOTION_API_KEY environment variable is not set.',
        );
        return;
      }

      // Act: Call the function with a valid (but test-specific) page ID.
      // Note: This ID is hardcoded and may need to be updated or mocked.
      final result = await markArticleAsProcessed(
        '26cca48a865381c2aa09de422ce0ef79',
      );

      // Assert: A non-empty string indicates a successful response.
      expect(result, isNotEmpty);
    }, tags: 'integration');
  });
}
