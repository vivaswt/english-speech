import 'dart:collection';

import 'package:english_speech/google/youtube.dart';
import 'package:english_speech/notion/notion_web_articles.dart';
import 'package:flutter/foundation.dart';
import 'package:http/src/client.dart';
import 'package:path_provider/path_provider.dart';

class YouTubeSubtitleBatch extends ChangeNotifier {
  BatchStatus _batchStatus = BatchStatus.initializing;
  final List<BatchItem> _batchItems = [];
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  late final Client _client;
  final List<PlayList> _playlists = [];
  late PlayList _selectedPlaylist;

  YouTubeSubtitleBatch() {
    initializeData();
  }

  UnmodifiableListView<BatchItem> get batchItems =>
      UnmodifiableListView(_batchItems);

  UnmodifiableListView<PlayList> get playLists =>
      UnmodifiableListView(_playlists);

  Future<void> initializeData() async {
    _client = (await _googleAuthService.authenticatedClient())!;
    _playlists.clear();
    _playlists.addAll(await getPlaylists(_client));
    _selectedPlaylist = _playlists.first;

    await _fillBatchItems();
  }

  Future<void> _fillBatchItems() async {
    _changeBatchStatus(BatchStatus.selectingData);

    final items = await getPlaylistItems(
      client: _client,
      title: _selectedPlaylist.title,
    );

    _batchItems.clear();
    _batchItems.addAll(
      items.map(
        (item) => BatchItem(
          title: item.title,
          url: item.url,
          id: item.id,
          thumbnailUrl: item.thumbnailUrl,
        ),
      ),
    );

    _changeBatchStatus(BatchStatus.waitToStart);
  }

  set selectedPlayList(PlayList playList) {
    _selectedPlaylist = playList;
    _fillBatchItems();
  }

  PlayList get selectedPlayList => _selectedPlaylist;

  BatchStatus get batchStatus => _batchStatus;

  Future<void> start() async {
    _changeBatchStatus(BatchStatus.processing);

    final tempFolder = await getTemporaryDirectory();

    for (int i = 0; i < _batchItems.length; i++) {
      final item = _batchItems[i];
      _changeItemStatus(i, ItemStatus.processing());

      try {
        if (_batchStatus != BatchStatus.processing) break;
        final subTitleTexts = await downloadSubtitle(
          item.url,
          folder: tempFolder.path,
        );

        if (_batchStatus != BatchStatus.processing) break;
        final page = await registWebArticle(
          WebArticlesPage(id: item.id, title: item.title, url: item.url),
        );
        await appendWebArticleChildren(page.id, subTitleTexts);

        if (_batchStatus != BatchStatus.processing) break;
        await deletePlayListItem(client: _client, id: item.id);

        _changeItemStatus(i, ItemStatus.done());
      } on Exception catch (e) {
        _changeItemStatus(i, ItemStatus.failed(message: e.toString()));
        _changeBatchStatus(BatchStatus.failed);
        break;
      }
    }

    // revert item status which is processing.
    _batchItems
        .where((item) => item.itemStatus.isProcessing)
        .forEach((item) => item.itemStatus = ItemStatus.waiting());

    final newStatus = switch (_batchStatus) {
      BatchStatus.processing => BatchStatus.completed,
      BatchStatus.waitToBeCancelled => BatchStatus.cancelled,
      _ => _batchStatus,
    };
    _changeBatchStatus(newStatus);
  }

  void cancel() {
    _batchStatus = BatchStatus.waitToBeCancelled;
    notifyListeners();
  }

  void _changeBatchStatus(BatchStatus status) {
    _batchStatus = status;
    notifyListeners();
  }

  void _changeItemStatus(int index, ItemStatus status) {
    _batchItems[index].itemStatus = status;
    notifyListeners();
  }
}

enum BatchStatus {
  initializing,
  selectingData,
  waitToStart,
  processing,
  waitToBeCancelled,
  cancelled,
  completed,
  failed,
}

class BatchItem {
  final String title;
  final String url;
  final String id;
  final String? thumbnailUrl;

  ItemStatus itemStatus;

  BatchItem({
    required this.title,
    required this.url,
    required this.id,
    this.thumbnailUrl,
  }) : itemStatus = ItemStatus.waiting();
}

sealed class ItemStatus {
  static ItemStatus waiting() => _Waiting();
  static ItemStatus processing() => _Processing();
  static ItemStatus done() => _Done();
  static ItemStatus failed({required String message}) =>
      _Failed(message: message);

  bool get isWaiting => this is _Waiting;
  bool get isProcessing => this is _Processing;
  bool get isDone => this is _Done;
  bool get isFailed => this is _Failed;

  R when<R>({
    R Function()? waiting,
    R Function()? processing,
    R Function()? done,
    R Function(String message)? failed,
    required R Function() orElse,
  }) {
    final s = this;
    if (s is _Waiting && waiting != null) return waiting();
    if (s is _Processing && processing != null) return processing();
    if (s is _Done && done != null) return done();
    if (s is _Failed && failed != null) return failed(s.message);
    return orElse();
  }
}

class _Waiting extends ItemStatus {}

class _Processing extends ItemStatus {}

class _Done extends ItemStatus {}

class _Failed extends ItemStatus {
  final String message;
  _Failed({required this.message});
}
