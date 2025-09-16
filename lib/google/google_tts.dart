import 'dart:convert';

import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

Future<String> callSynthesizeApi(List<String> inputTexts) async {
  const String url = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  final Map<String, String> headers = {
    'x-goog-api-key': await SettingsService().getTtsApiKey(),
    'chaset': 'UTF-8',
    'Content-Type': 'application/json',
  };

  final body = {
    'input': {'text': inputTexts.join('\n')},
    'voice': {
      'languageCode': 'en-US',
      'name': 'en-US-Wavenet-H',
      'ssmlGender': 'FEMALE',
    },
    'audioConfig': {'audioEncoding': 'LINEAR16'},
  };

  final res = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 200) {
    final Map<String, dynamic> responseJson = jsonDecode(res.body);
    if (responseJson case {'audioContent': final String content}) {
      return content;
    } else {
      throw Exception(
        'Failed to synthesize text. The audio content field is missing.',
      );
    }
  } else {
    throw Exception(
      'Failed to call synthesize API. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}
