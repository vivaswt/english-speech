import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:english_speech/cashe_manager.dart';
import 'package:english_speech/common_types.dart';
import 'package:english_speech/settings_service.dart';
import 'package:http/http.dart' as http;

Future<String> callSynthesizeApi(
  List<String> inputTexts, {
  Voice? voice,
}) async {
  const String url = 'https://texttospeech.googleapis.com/v1/text:synthesize';

  final Map<String, String> headers = {
    'x-goog-api-key': await SettingsService().getTtsApiKey(),
    'chaset': 'UTF-8',
    'Content-Type': 'application/json',
  };

  voice ??= Voice('en-US-Wavenet-E', 'FEMALE');

  final body = {
    'input': {'text': inputTexts.join('\n')},
    'voice': {
      'languageCode': 'en-US',
      'name': voice.name,
      'ssmlGender': voice.gender,
    },
    'audioConfig': {
      'audioEncoding': 'LINEAR16',
      'speakingRate': await SettingsService().getSpeakingRate(),
    },
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

Future<JSONString> fetchVoicesList() async {
  const String url = 'https://texttospeech.googleapis.com/v1/voices';

  final Map<String, String> headers = {
    'x-goog-api-key': await SettingsService().getTtsApiKey(),
    'chaset': 'UTF-8',
    'Content-Type': 'application/json',
  };

  final queryParameters = {'languageCode': 'en-US'};
  final uri = Uri.parse(url).replace(queryParameters: queryParameters);

  final res = await http.get(uri, headers: headers);

  if (res.statusCode == 200) {
    return res.body;
  } else {
    throw Exception(
      'Failed to fetch voices list. Status Code = ${res.statusCode}, Message = ${res.body}',
    );
  }
}

class Voice {
  final String name;
  final String gender;

  Voice(this.name, this.gender);
}

Future<List<Voice>> parseVoicesList(JSONString jsonString) async {
  final json = jsonDecode(jsonString);
  final voices = pick(json, 'voices');

  return voices.asListOrThrow((p) {
    final name = p('name').asStringOrThrow();
    final gender = p('ssmlGender').asStringOrThrow();
    return Voice(name, gender);
  });
}

Future<List<Voice>> getVoicesList() async {
  final manager = CacheManager();
  const casheKey = 'voices_list';

  final cachedResult = await manager.readCache(casheKey);

  if (cachedResult != null) {
    return parseVoicesList(cachedResult);
  } else {
    final result = await fetchVoicesList();
    await manager.saveCache(casheKey, result);
    return parseVoicesList(result);
  }
}
