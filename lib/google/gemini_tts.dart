import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:english_speech/common_types.dart';
import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

Future<String> getSpeechAudio(List<String> content, String voiceName) =>
    fetchSpeechGeneration(content, voiceName).then(parseSpeechGeneration);

Future<JSONString> fetchSpeechGeneration(
  List<String> content,
  String voiceName,
) async {
  const String url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent';

  final Map<String, String> headers = {
    'x-goog-api-key': await SettingsService().getGeminiApiKey(),
    'Content-Type': 'application/json',
  };

  final speedPercent = await SettingsService().getSpeakingRate() * 100;
  final instruction = 'Speak at $speedPercent% of the noraml speed:\n';

  final body = {
    "contents": [
      {
        "parts": [
          {"text": instruction + content.join(r'\n')},
        ],
      },
    ],
    // "systemInstruction": {
    //   "parts": [
    //     {"text": instruction},
    //   ],
    // },
    "generationConfig": {
      "responseModalities": ["AUDIO"],
      "speechConfig": {
        "voiceConfig": {
          "prebuiltVoiceConfig": {"voiceName": voiceName},
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
      'Failed to fetch speech generation. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

String parseSpeechGeneration(JSONString jsonString) {
  final json = jsonDecode(jsonString);
  final response = pick(json);
  final String? resultData = response(
    'candidates',
    0,
    'content',
    'parts',
    0,
    'inlineData',
    'data',
  ).asStringOrNull();
  final String? blockReason = response(
    'promptFeedback',
    'blockReason',
  ).asStringOrNull();

  if (resultData == null) {
    throw Exception('Fail to parseSpeechGeneration - reason: $blockReason');
  }

  return resultData;
}

const List<String> predifinedVoiceNames = [
  "Zephyr",
  "Puck",
  "Charon",
  "Kore",
  "Fenrir",
  "Leda",
  "Orus",
  "Aoede",
  "Callirrhoe",
  "Autonoe",
  "Enceladus",
  "Iapetus",
  "Umbriel",
  "Algieba",
  "Despina",
  "Erinome",
  "Algenib",
  "Rasalgethi",
  "Laomedeia",
  "Achernar",
  "Alnilam",
  "Schedar",
  "Gacrux",
  "Pulcherrima",
  "Achird",
  "Zubenelgenubi",
  "Vindemiatrix",
  "Sadachbia",
  "Sadaltager",
  "Sulafat",
];
