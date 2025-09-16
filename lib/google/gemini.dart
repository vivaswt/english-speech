import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:english_speech/common_types.dart';
import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

Future<List<String>> getSummurizedContent(List<String> content) =>
    fetchSummurizedContent(content).then(parseSummurizedContent);

Future<JSONString> fetchSummurizedContent(List<String> content) async {
  const String url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final Map<String, String> headers = {
    'x-goog-api-key': await SettingsService().getGeminiApiKey(),
    'Content-Type': 'application/json',
  };

  final body = {
    "contents": [
      {
        "parts": [
          {"text": content.join('\n')},
        ],
      },
    ],
    "systemInstruction": {
      "parts": [
        {"text": summarizeInstruction},
      ],
    },
    "generationConfig": {
      "responseMimeType": "application/json",
      "responseSchema": {
        "type": "OBJECT",
        "properties": {
          "paragraphs": {
            "type": "ARRAY",
            "items": {"type": "STRING"},
          },
        },
      },
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
      'Failed to web articles. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

List<String> parseSummurizedContent(JSONString jsonString) {
  final json = jsonDecode(jsonString);
  final response = pick(json);
  final String? resultJsonString = response(
    'candidates',
    0,
    'content',
    'parts',
    0,
    'text',
  ).asStringOrNull();
  final String? blockReason = response(
    'promptFeedback',
    'blockReason',
  ).asStringOrNull();

  if (resultJsonString == null) {
    throw Exception('Fail to parseSummurizedContent - reason: $blockReason');
  }

  final resultJson = jsonDecode(resultJsonString);

  return pick(
    resultJson,
    'paragraphs',
  ).asListOrThrow((p) => p.asString()).toList();
}

const String summarizeInstruction = '''
You are an English teacher helping Japanese high school students improve their English listening skills.

Your task is to process the attached article in simpler English.

* If the original article is longer than 800 words, summarize it in simpler English so the final text is under 800 words.
* If the original article is 800 words or fewer, rewrite it in simpler English without summarizing, keeping the same meaning and flow.
* Write in plain paragraph form.

Follow these rules:
* Use vocabulary and grammar at CEFR A2–B1 level.
* Break long or complex sentences into shorter ones.
* Do not add any commentary or analysis.
* Make sure the total word count is no more than 800 words.
''';
