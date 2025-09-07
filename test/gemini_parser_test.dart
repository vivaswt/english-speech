import 'package:english_speech/gemini.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSummurizedContent', () {
    test('should correctly parse a valid JSON response with paragraphs', () {
      // Arrange: A mock API response where the 'text' field contains a JSON
      // string with a list of paragraphs.
      const mockApiResponse = '''
      {
        "candidates": [
          {
            "content": {
              "parts": [
                {
                  "text": "{\\"paragraphs\\": [\\"This is the first paragraph.\\", \\"This is the second paragraph.\\"]}"
                }
              ]
            }
          }
        ]
      }
      ''';

      // Act
      final result = parseSummurizedContent(mockApiResponse);

      // Assert
      expect(result, isA<List<String>>());
      expect(result, hasLength(2));
      expect(result[0], 'This is the first paragraph.');
      expect(result[1], 'This is the second paragraph.');
    });

    test('should return an empty list when the paragraphs array is empty', () {
      // Arrange
      const mockApiResponse = '''
      {
        "candidates": [
          {
            "content": {
              "parts": [
                {
                  "text": "{\\"paragraphs\\": []}"
                }
              ]
            }
          }
        ]
      }
      ''';

      // Act
      final result = parseSummurizedContent(mockApiResponse);

      // Assert
      expect(result, isA<List<String>>());
      expect(result, isEmpty);
    });

    test('should throw an exception when content is blocked by the API', () {
      // Arrange: A response indicating the prompt was blocked.
      const mockApiResponse = '''
      {
        "candidates": [],
        "promptFeedback": {
          "blockReason": "SAFETY"
        }
      }
      ''';

      // Act & Assert: Expect an exception with the block reason.
      expect(
        () => parseSummurizedContent(mockApiResponse),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains('Fail to parseSummurizedContent - reason: SAFETY'),
          ),
        ),
      );
    });

    test('should throw a PickException when the text field is missing', () {
      // Arrange: A malformed response missing the 'text' part.
      const mockApiResponse = '''
      {
        "candidates": [
          {
            "content": {
              "parts": [
                {}
              ]
            }
          }
        ]
      }
      ''';

      // Act & Assert: The function should throw an exception because 'text' is null.
      expect(
        () => parseSummurizedContent(mockApiResponse),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('combination: fetch & parse', () {
    test('normal case', () async {
      final result = parseSummurizedContent(
        await fetchSummurizedContent(sampleArticle1),
      );
      expect(result, isNotEmpty);
      result.forEach(print);
    });
  });
}

final List<String> sampleArticle1 =
    '''
Because web components are so universal, it’s far easier to repurpose one for a web UI app than to use a widget written for some other toolkit or windowing system. This doesn’t just include common components like forms and input fields, but more complex interfaces like interactive 3D charts. Most everything that can be part of a native app’s UI can be delivered as a web component of some kind.
Web UI apps also offer portability. It’s far easier to deliver a cross-platform version of a web UI app than its native counterpart. Just about all the abstractions for the platform, such as how to deal with the clipboard, are handled by the browser runtime.
All the above advantages for web UIs come with drawbacks. The single biggest one is dependency on the web browser—whether it’s one bundled with the application or a native web view on the target platform.
Bundling a browser with the application is the most common approach; it’s what Electron and its spin-offs do. This gives developers fine-grained control over which edition of the browser is used, what requirements it supports, and how it supports them. But that control comes with a massive downside in the size of the binary artifact. Browser bundles can reach 100MB or so for even a simple “hello world” application.
'''
        .split('\n');
