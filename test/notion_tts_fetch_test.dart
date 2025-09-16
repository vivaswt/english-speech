import 'package:english_speech/notion/notion_contents_for_tts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io' show Platform;

void main() {
  group('fetchContentsForTTS', () {
    // This test makes a real network request to the Notion API.
    // It requires the NOTION_API_KEY environment variable to be set.
    // Example: NOTION_API_KEY="your_key_here" flutter test test/notion_tts_fetch_test.dart
    test(
      'should fetch data from Notion API when NOTION_API_KEY is provided as an environment variable',
      () async {
        // Arrange: Check if the environment variable is set.
        final apiKey = Platform.environment['NOTION_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          markTestSkipped(
            'Skipping test: NOTION_API_KEY environment variable is not set.',
          );
          return;
        }

        // Act & Assert
        // We expect the function to complete without throwing an exception,
        // which would indicate a successful API call (e.g., not a 401 Unauthorized).
        // A more specific assertion could be made if we knew the expected structure of a successful, non-empty response.
        final result = await fetchContentsForTTS();
        expect(result, isA<String>());
        expect(result, isNotEmpty);
      },
      tags: 'integration',
    );
  });
}
