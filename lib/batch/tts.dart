import 'dart:io';
import 'package:english_speech/google/gemini_tts.dart';
import 'package:english_speech/settings_service.dart';
import 'package:path/path.dart' as p;

import 'package:english_speech/extension/list_extension.dart';
import 'package:english_speech/google/google_tts.dart';
import 'package:english_speech/notion/notion_contents_for_tts.dart';
import 'package:english_speech/wav_lib.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wav/wav.dart';

class TtsBatch extends ChangeNotifier {
  BatchStatus status = BatchStatus.init;
  List<TTSContent> contents = [];
  List<ItemStatus> itemStatuses = [];

  TtsBatch();

  void selectData() async {
    status = BatchStatus.selectingData;
    notifyListeners();

    contents = await getContentsForTTS();

    itemStatuses = List.filled(contents.length, ItemStatus.waiting);
    status = BatchStatus.waitToStart;
    notifyListeners();
  }

  void start(TtsApiSelection apiSelection) async {
    status = BatchStatus.processing;
    notifyListeners();

    // main loop
    for (int i = 0; i < contents.length; i++) {
      if (status != BatchStatus.processing) break;

      try {
        final wav = await _synthesizeAndJoinAudio(
          contents[i],
          apiSelection: apiSelection,
          onProgress: (p) {
            changeItemStatus(
              i,
              ItemStatus.processing('synthesize', progress: p),
            );
          },
        );

        changeItemStatus(i, ItemStatus.processing('save'));
        await writeWav(contents[i].title, wav);

        changeItemStatus(i, ItemStatus.processing('mark as complete'));
        await markAsComplete(contents[i].id!);

        changeItemStatus(i, ItemStatus.done);
      } on Exception catch (e) {
        changeItemStatus(i, ItemStatus.failed(error: e, message: e.toString()));

        status = BatchStatus.failed;
        notifyListeners();
        break;
      }
    }

    // revert item status which is processing.
    for (int i = 0; i < contents.length; i++) {
      itemStatuses[i].when(
        processing: (_, __) {
          itemStatuses[i] = ItemStatus.waiting;
          notifyListeners();
        },
        orElse: () {},
      );
    }

    status = switch (status) {
      BatchStatus.processing => BatchStatus.completed,
      BatchStatus.waitToBeCancelled => BatchStatus.cancelled,
      _ => status,
    };
    notifyListeners();
  }

  void cancel() {
    status = BatchStatus.waitToBeCancelled;
    notifyListeners();
  }

  void changeItemStatus(int index, ItemStatus status) {
    itemStatuses[index] = status;
    notifyListeners();
  }

  Future<void> dummyProcess(TTSContent content) async {
    await Future.delayed(Duration(seconds: 2));
  }

  static const int _paragraphsLength = 3;

  /// Synthesizes audio from [TTSContent] in chunks and joins them into a single [Wav] object.
  ///
  /// This function divides the content into smaller paragraph groups, calls the
  /// TTS API for each group, and reports progress via the [onProgress] callback.
  Future<Wav> _synthesizeAndJoinAudio(
    TTSContent ttsContent, {
    required TtsApiSelection apiSelection,
    required void Function(double) onProgress,
  }) async {
    V selectVoice<V>(List<V> vs) => vs.randomItem;
    Future<String> Function(List<String>) ttsApi;

    if (apiSelection == TtsApiSelection.googleCloud) {
      final voices = (await getVoicesList())
          .where((v) => v.name.contains('Wavenet'))
          .toList();

      final voice = selectVoice(voices);
      ttsApi = (inputTexts) => callSynthesizeApi(inputTexts, voice: voice);
    } else {
      final voice = selectVoice(predifinedVoiceNames);
      ttsApi = (inputTexts) => getSpeechAudio(inputTexts, voice);
    }

    final paragraphsLength = switch (apiSelection) {
      TtsApiSelection.gemini => ttsContent.content.length,
      TtsApiSelection.googleCloud => _paragraphsLength,
    };
    final paragraphsList = ttsContent.content.divideBy(paragraphsLength);

    final List<String> bs = [];
    for (var i = 0; i < paragraphsList.length; i++) {
      if (status != BatchStatus.processing) break;

      onProgress((i + 1) / paragraphsList.length);

      final paragraphs = paragraphsList[i];
      final r = await ttsApi(paragraphs);
      //await Future.delayed(Duration(milliseconds: 800));
      //final r = await File('temp_data/linear0.txt').readAsString();

      bs.add(r);
    }

    return joinWavsFromBase64(
      bs,
      inPCM: apiSelection == TtsApiSelection.gemini,
    );
  }

  Future<File> writeWav(String title, Wav wav) async {
    final path = await editFilePath(title);
    await wav.writeFile(path);
    return File(path);
  }

  Future<String> editFilePath(String title) async {
    String saveFolder = await SettingsService().getSaveFolderPath();

    if (saveFolder.isEmpty) {
      final directory = await getTemporaryDirectory();
      saveFolder = directory.path;
    }

    final parsedPath = p.joinAll([
      saveFolder,
      sanitizeFileName(title) + '.wav',
    ]);
    return parsedPath;
  }

  String sanitizeFileName(String fileName) {
    // Define a set of characters that are not allowed in file names on most operating systems.
    final invalidChars = RegExp(r'[<>:"/\\|?*]');

    // Replace invalid characters with an underscore.
    // The `replaceAll` method is a good choice for this task.
    String sanitizedName = fileName.replaceAll(invalidChars, '_');

    // Also handle leading/trailing spaces and dots, which can be problematic.
    sanitizedName = sanitizedName.trim();
    if (sanitizedName.isNotEmpty && sanitizedName.startsWith('.')) {
      sanitizedName = '_${sanitizedName.substring(1)}';
    }

    // Ensure the sanitized name is not empty.
    if (sanitizedName.isEmpty) {
      return 'untitled';
    }

    return sanitizedName;
  }
}

enum BatchStatus {
  init,
  selectingData,
  waitToStart,
  processing,
  waitToBeCancelled,
  cancelled,
  completed,
  failed,
}

//enum ItemStatus { waiting, processing, done, failed }
sealed class ItemStatus {
  static ItemStatus get waiting => _Waiting();
  static ItemStatus processing(String processingName, {double? progress}) =>
      _Processing(processingName: processingName, progress: progress);
  static ItemStatus get done => _Done();
  static ItemStatus failed({
    required Exception error,
    required String message,
  }) => _Failed(error: error, message: message);

  bool get isWaiting => this is _Waiting;
  bool get isProcessing => this is _Processing;
  bool get isDone => this is _Done;
  bool get isFailed => this is _Failed;

  /// Handles all states of [ItemStatus], allowing for data extraction.
  R when<R>({
    R Function()? waiting,
    R Function(String processingName, double? progress)? processing,
    R Function()? done,
    R Function(Exception error, String message)? failed,
    required R Function() orElse,
  }) {
    final s = this;
    if (s is _Waiting && waiting != null) {
      return waiting();
    }
    if (s is _Processing && processing != null) {
      return processing(s.processingName, s.progress);
    }
    if (s is _Done && done != null) {
      return done();
    }
    if (s is _Failed && failed != null) {
      return failed(s.error, s.message);
    }
    return orElse();
  }
}

class _Waiting extends ItemStatus {}

class _Processing extends ItemStatus {
  final String processingName;
  final double? progress; // from 0(which means 0%) to 1(which means 100%)

  _Processing({required this.processingName, this.progress});
}

class _Done extends ItemStatus {}

class _Failed extends ItemStatus {
  final Exception error;
  final String message;
  _Failed({required this.error, required this.message});
}
