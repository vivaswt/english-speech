import 'dart:convert';
import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

Future<String> registForTTS({
  required String title,
  required String url,
  required List<String> content,
}) async {
  const String endPointUrl = 'https://api.notion.com/v1/pages';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  final countOfWords = content
      .where((line) => line.isNotEmpty)
      .map((line) => line.split(' ').length)
      .reduce((v, e) => v + e);

  final properties = {
    'Title': {
      'type': 'title',
      'title': [
        {
          'type': 'text',
          'text': {'content': title, 'link': null},
        },
      ],
    },
    'URL': {'url': url},
    'Status': {
      'status': {'name': 'unprocessed'},
    },
    'Count of Words': {'number': countOfWords},
  };

  final body = {
    'parent': {'database_id': '266ca48a8653800b99d0e4d50d4595fb'},
    'properties': properties,
    'children': toBlocks(content),
  };

  final res = await http.post(
    Uri.parse(endPointUrl),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to regist for TTS - Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

List<Map<String, dynamic>> toBlocks(List<String> content) {
  Map<String, dynamic> toParagraph(String line) => {
    'object': 'block',
    'type': 'paragraph',
    'paragraph': {
      'rich_text': [
        {
          'type': 'text',
          'text': {'content': line},
        },
      ],
    },
  };

  return content.map(toParagraph).toList();
}
