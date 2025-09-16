import 'package:english_speech/notion/notion_web_articles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deep_pick/deep_pick.dart';

void main() {
  // Group tests related to Notion data parsing for better organization.
  group('Notion Data Parsing', () {
    // Test case for the "happy path" where parsing is successful.
    test('parseWebArticles successfully parses a valid JSON response', () {
      // 1. Arrange: Create mock JSON data that mimics the Notion API response.
      const mockJson = '''
{
  "object": "list",
  "results": [
    {
      "object": "page",
      "id": "page-1",
      "created_time": "2025-08-30T08:10:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:10:00.000Z"
          }
        },
        "URL": {
          "url": "businessinsider.com/goo...2025-8"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "Is Google's new AI image-editing tool an Adobe-killer? We tried"
              },
              "plain_text": "Is Google's new AI image-editing tool an Adobe-killer? We tried"
            }
          ]
        }
      }
    },
    {
      "object": "page",
      "id": "page-2",
      "created_time": "2025-08-30T08:09:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:09:00.000Z"
          }
        },
        "URL": {
          "url": "gamesradar.com/gam...ge-of"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "Hideo Kojima thinks video games are in the middle of a major sl"
              },
              "plain_text": "Hideo Kojima thinks video games are in the middle of a major sl"
            }
          ]
        }
      }
    },
    {
      "object": "page",
      "id": "page-3",
      "created_time": "2025-08-30T08:08:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:08:00.000Z"
          }
        },
        "URL": {
          "url": "zdnet.com/hom...rance/"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "Your Windows PC just got a big Bluetooth audio upgrade from"
              },
              "plain_text": "Your Windows PC just got a big Bluetooth audio upgrade from"
            }
          ]
        }
      }
    },
    {
      "object": "page",
      "id": "page-4",
      "created_time": "2025-08-30T08:08:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:08:00.000Z"
          }
        },
        "URL": {
          "url": "techradar.com/aud...d-soon"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "Hard truth: all women want AirPods with IR cameras for safety a"
              },
              "plain_text": "Hard truth: all women want AirPods with IR cameras for safety a"
            }
          ]
        }
      }
    },
    {
      "object": "page",
      "id": "page-5",
      "created_time": "2025-08-30T08:07:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:07:00.000Z"
          }
        },
        "URL": {
          "url": "polygon.com/nin...rld-8/"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "Welp, Mario Kart 8 on Switch is outselling Mario Kart World now"
              },
              "plain_text": "Welp, Mario Kart 8 on Switch is outselling Mario Kart World now"
            }
          ]
        }
      }
    },
    {
      "object": "page",
      "id": "page-6",
      "created_time": "2025-08-30T08:03:00.000Z",
      "properties": {
        "Processed": {
          "checkbox": false
        },
        "Created time": {
          "date": {
            "start": "2025-08-30T08:03:00.000Z"
          }
        },
        "URL": {
          "url": "howtogeek.com/so-...th-it/"
        },
        "Source": {
          "title": [
            {
              "text": {
                "content": "So You've Set Up Linux On Windows Using WSL. Here's What To"
              },
              "plain_text": "So You've Set Up Linux On Windows Using WSL. Here's What To"
            }
          ]
        }
      }
    }
  ],
  "next_cursor": null,
  "has_more": false
}
      ''';

      // 2. Act: Call the function under test with the mock data.
      final articles = parseWebArticles(mockJson);

      // 3. Assert: Verify that the output is correct.
      expect(articles, isA<List<WebArticlesPage>>());
      expect(articles.length, 6);

      expect(articles[0].id, 'page-1');
      expect(
        articles[0].title,
        "Is Google's new AI image-editing tool an Adobe-killer? We tried",
      );

      expect(articles[1].id, 'page-2');
      expect(
        articles[1].title,
        'Hideo Kojima thinks video games are in the middle of a major sl',
      );
    });

    // Test case for handling a valid but empty list of results.
    test('parseWebArticles returns an empty list for empty results array', () {
      // Arrange
      const mockJson = '{"results": []}';

      // Act
      final articles = parseWebArticles(mockJson);

      // Assert
      expect(articles, isA<List<WebArticlesPage>>());
      expect(articles.isEmpty, isTrue);
    });

    // Test case for handling malformed data where a required field is missing.
    test('parseWebArticles throws PickException for missing title', () {
      // Arrange
      const mockJson = '''
      {
        "results": [
          { "id": "12345" }
        ]
      }
      ''';

      // Act & Assert: Verify that calling the function throws the expected exception.
      expect(() => parseWebArticles(mockJson), throwsA(isA<PickException>()));
    });
  });
}
