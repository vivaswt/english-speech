import 'dart:convert';
import 'package:deep_pick/deep_pick.dart';
import 'package:english_speech/common_types.dart';
import 'package:english_speech/notion/notion_web_articles.dart';
import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

class TTSContent {
  final String? id;
  final String title;
  final String url;
  final List<String> content;

  TTSContent({
    this.id,
    required this.title,
    required this.url,
    this.content = const [],
  });

  int get countOfWords => content.isEmpty
      ? 0
      : content
            .where((line) => line.isNotEmpty)
            .map((line) => line.split(' ').length)
            .reduce((v, e) => v + e);

  TTSContent copyWith({
    String? id,
    String? title,
    String? url,
    List<String>? content,
  }) => TTSContent(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url ?? this.url,
    content: content ?? this.content,
  );
}

Future<TTSContent> registForTTS(TTSContent ttsContent) async {
  const String endPointUrl = 'https://api.notion.com/v1/pages';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  final properties = {
    'Title': {
      'type': 'title',
      'title': [
        {
          'type': 'text',
          'text': {'content': ttsContent.title, 'link': null},
        },
      ],
    },
    'URL': {'url': ttsContent.url},
    'Status': {
      'status': {'name': 'unprocessed'},
    },
    'Count of Words': {'number': ttsContent.countOfWords},
  };

  final body = {
    'parent': {'database_id': '266ca48a8653800b99d0e4d50d4595fb'},
    'properties': properties,
    'children': toBlocks(ttsContent.content),
  };

  final res = await http.post(
    Uri.parse(endPointUrl),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    final newId = pick(jsonDecode(res.body), 'id').asStringOrThrow();
    return ttsContent.copyWith(id: newId);
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

Future<List<TTSContent>> getContentsForTTS() async {
  Future<TTSContent> fillTexts(TTSContent content) async => getTextsForTTS(
    content.id!,
  ).then((txts) => content.copyWith(content: txts));

  final contents = await fetchContentsForTTS().then(parseContentsForTTS);
  return Future.wait(contents.map(fillTexts));
}

Future<JSONString> fetchContentsForTTS() async {
  const dataSourceId = '266ca48a865380c3a4ef000b36793bf2';
  const url = 'https://api.notion.com/v1/data_sources/$dataSourceId/query';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2025-09-03',
    'Content-Type': 'application/json',
  };

  const Map<String, dynamic> body = {
    "sorts": [
      {"property": "Creation Date", "direction": "ascending"},
    ],
    "filter": {
      "property": "Status",
      "status": {"equals": "unprocessed"},
    },
  };

  final res = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to fetch contents for TTS. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

Future<List<TTSContent>> parseContentsForTTS(JSONString jsonString) async {
  final json = jsonDecode(jsonString);

  return pick(json, 'results').asListOrThrow((result) {
    final id = result('id').required().asString();
    final title = result(
      'properties',
      'Title',
      'title',
      0,
      'plain_text',
    ).required().asString();
    final url = result('properties', 'URL', 'url').required().asString();

    return TTSContent(id: id, title: title, url: url);
  });
}

Future<List<String>> getTextsForTTS(String pageId) async =>
    fetchBlockChildren(pageId)
        .then(parseBlockChildren)
        .then(
          (bs) => bs
              .expand((b) => b.format())
              .where((txt) => txt.isNotEmpty)
              .toList(),
        );

Future<String> markAsComplete(String pageId) async {
  final String endPointUrl = 'https://api.notion.com/v1/pages/$pageId';

  final Map<String, String> headers = {
    'Authorization': await SettingsService().getNotionApiKey(),
    'Notion-Version': '2025-09-03',
    'Content-Type': 'application/json',
  };

  final properties = {
    'Status': {
      'status': {'name': 'complete'},
    },
  };

  final body = {'properties': properties};

  final res = await http.patch(
    Uri.parse(endPointUrl),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to mark tts content as complete.  - Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}
