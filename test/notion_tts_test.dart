import 'dart:convert';
import 'dart:io';

import 'package:english_speech/google/google_tts.dart';
import 'package:english_speech/notion/notion_contents_for_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wav/wav.dart';

void main() {
  group('post & read records', () {
    test('normal regist', () async {
      final result = await registForTTS(
        TTSContent(
          title: 'My first test',
          url: 'https://www.gamesradar.com/',
          content: content1,
        ),
      );
      expect(result.id, isNotEmpty);
    });

    test('read contents and their texts', () async {
      final contents = await getContentsForTTS();
      expect(contents, isNotEmpty);

      final content = contents.firstWhere((c) => c.title == 'My first test');
      final texts = await getTextsForTTS(content.id!);
      expect(
        listEquals(texts, content1.where((line) => line.isNotEmpty).toList()),
        isTrue,
      );
    });
  });

  group('tts', () {
    test('noraml tts', () async {
      final result = await callSynthesizeApi([content2[1]]);
      expect(result, isNotEmpty);
    });
  });

  // group('tts create file', () {
  //   test('normal create file', () async {
  //     print('start to create file');
  //     for (int i = 0; i < content2.length; i++) {
  //       await saveSynthesizeData('temp_data/linear$i.txt', content2[i]);
  //     }
  //   });
  // });

  group('tts join', () {
    test('normal join', () async {
      await joinAudioData();
    });
  });
}

Future<void> saveSynthesizeData(String fileName, String data) async {
  final file = File(fileName);
  final result = await callSynthesizeApi([data]);
  await file.writeAsString(result);
  print('${file.path} is created.');
}

Future<void> joinAudioData() async {
  final List<Wav> wavs = await Future.wait(
    Iterable.generate(3, (i) => 'temp_data/linear$i.txt')
        .map((path) => File(path).readAsString())
        .map((faTxt) => faTxt.then(base64.decode).then(Wav.read)),
  );

  final List<Float64List> channels = wavs.fold(
    List<Float64List>.generate(
      wavs.first.channels.length,
      (_) => Float64List(0),
    ),
    (cs, wav) => List<Float64List>.generate(
      cs.length,
      (i) => Float64List.fromList([...cs[i], ...wav.channels[i]]),
    ),
  );

  final samplePerSecond = wavs.first.samplesPerSecond;

  final newWav = Wav(channels, samplePerSecond);
  await newWav.writeFile('temp_data/joined.wav');
  print('joined.wav is created.');
}

final List<String> content1 =
    '''
Former Nintendo software developer Ken Watanabe, not to be confused with one of the most famous Japanese actors of all time, says his ex-employer doesn't create entirely new franchises all too often simply because it doesn't need to.
From Watanabe's perspective, Nintendo already has plenty of beloved IP to use essentially as templates for creating new and exciting gameplay experiences.
'''
        .split('\n');

const List<String> content2 = [
  'Tutorials helped a bit with understanding the basics of modeling. But there’s so much information out there that it often takes an hour scrolling through videos and forums just to learn one tiny step.',
  'After successfully pairing NotebookLM with Figma, I thought why not try it with Blender?',
  'Once my Blender notebook was set up, the learning curve didn’t feel like a wall anymore.',
];
