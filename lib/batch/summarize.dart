// --- States ---
import 'package:english_speech/extension/iterable_extension.dart';
import 'package:english_speech/google/gemini.dart';
import 'package:english_speech/notion/notion_contents_for_tts.dart';
import 'package:english_speech/service/log.dart';
import 'package:flutter/material.dart';

import 'package:english_speech/notion/notion_web_articles.dart' as notion;

sealed class BatchState {}

class InitState extends BatchState {}

class FetchingState extends BatchState {}

class FailToFetchState extends BatchState {}

class SelectingItemsState extends BatchState {
  final List<BatchItem> items;

  SelectingItemsState(this.items);
}

class ProcessingState extends BatchState {
  final List<BatchItem> items;

  ProcessingState(this.items);
}

class WaitingCancelState extends BatchState {
  final List<BatchItem> items;

  WaitingCancelState(this.items);
}

class CanceledState extends BatchState {
  final List<BatchItem> items;

  CanceledState(this.items);
}

class FailedState extends BatchState {
  final List<BatchItem> items;

  FailedState(this.items);
}

class DoneState extends BatchState {
  final List<BatchItem> items;

  DoneState(this.items);
}

// --- Events ---
// The event class only needs its data if the event occurs outside of the Batch class.
sealed class BatchEvent {}

class Fetch extends BatchEvent {}

class FetchSuccess extends BatchEvent {
  final List<FetchedItem> items;

  FetchSuccess(this.items);
}

class FetchFail extends BatchEvent {}

class SelectItem extends BatchEvent {
  final String id;
  final bool selected;

  SelectItem({required this.id, required this.selected});
}

class SelectAllItems extends BatchEvent {}

class DeselectAllItems extends BatchEvent {}

class RunBatch extends BatchEvent {}

class StartBatchOfItem extends BatchEvent {
  final String id;

  StartBatchOfItem({required this.id});
}

class CompleteBatchOfItem extends BatchEvent {
  final String id;

  CompleteBatchOfItem({required this.id});
}

class CanceledBatchOfItem extends BatchEvent {
  final String id;

  CanceledBatchOfItem({required this.id});
}

class FailBatchOfItem extends BatchEvent {
  final String id;

  FailBatchOfItem({required this.id});
}

class CancelBatch extends BatchEvent {}

class CanceledBatch extends BatchEvent {}

class FailedBatch extends BatchEvent {}

class CompleteBatch extends BatchEvent {}

// --- Data ---
class FetchedItem {
  final notion.WebArticlesPage page;
  final List<notion.Block> blocks;

  FetchedItem({required this.page, required this.blocks});
}

enum BatchItemState { waiting, processing, done, failed }

class BatchItem {
  final String id;
  final String title;
  final String url;
  final List<String> texts;
  final bool selected;
  final BatchItemState state;

  BatchItem({
    required this.id,
    required this.title,
    required this.url,
    required this.texts,
    required this.selected,
    required this.state,
  });

  BatchItem copyWith({bool? selected, BatchItemState? state}) => BatchItem(
    id: id,
    title: title,
    url: url,
    texts: texts,
    selected: selected ?? this.selected,
    state: state ?? this.state,
  );
}

extension BatchItemsExtension on List<BatchItem> {
  List<BatchItem> copyWithItem(BatchItem replacedItem) =>
      map((item) => item.id == replacedItem.id ? replacedItem : item).toList();
}

// --- Batch ---
class Batch {
  final ValueNotifier<BatchState> _state = ValueNotifier(InitState());
  bool _toContinueMainLoop = true;

  ValueNotifier<BatchState> get state => _state;

  Future<void> dispatch(BatchEvent event) async {
    switch ((_state.value, event)) {
      case (InitState(), Fetch()):
        _state.value = FetchingState();
        _fetch();

      case (FetchingState(), FetchSuccess(:final items)):
        final batchItems = _convertToBatchItems(items);
        _state.value = SelectingItemsState(batchItems);

      case (FetchingState(), FetchFail()):
        _state.value = FailToFetchState();

      case (
        SelectingItemsState(:final items),
        SelectItem(:final id, :final selected),
      ):
        final newItems = items.map(
          (item) => item.id == id ? item.copyWith(selected: selected) : item,
        );
        _state.value = SelectingItemsState(newItems.toList());

      case (SelectingItemsState(:final items), SelectAllItems()):
        final newItems = items.map((item) => item.copyWith(selected: true));
        _state.value = SelectingItemsState(newItems.toList());

      case (SelectingItemsState(:final items), DeselectAllItems()):
        final newItems = items.map((item) => item.copyWith(selected: false));
        _state.value = SelectingItemsState(newItems.toList());

      case (SelectingItemsState(:final items), RunBatch()):
        final targetItems = items.where((item) => item.selected).toList();
        _toContinueMainLoop = true;
        _state.value = ProcessingState(targetItems);
        _runBatch(targetItems);

      case (ProcessingState(:final items), CancelBatch()):
        _toContinueMainLoop = false;
        _state.value = WaitingCancelState(items);

      case (ProcessingState(:final items), StartBatchOfItem(:final id)):
        _state.value = ProcessingState(
          _updateItemStatus(id, items, BatchItemState.processing),
        );

      case (ProcessingState(:final items), CompleteBatchOfItem(:final id)):
        _state.value = ProcessingState(
          _updateItemStatus(id, items, BatchItemState.done),
        );

      case (ProcessingState(:final items), FailBatchOfItem(:final id)):
        _toContinueMainLoop = false;
        _state.value = ProcessingState(
          _updateItemStatus(id, items, BatchItemState.failed),
        );

      case (ProcessingState(:final items), CanceledBatchOfItem(:final id)):
        _state.value = ProcessingState(
          _updateItemStatus(id, items, BatchItemState.waiting),
        );

      case (WaitingCancelState(:final items), CompleteBatchOfItem(:final id)):
        _state.value = WaitingCancelState(
          _updateItemStatus(id, items, BatchItemState.done),
        );

      case (WaitingCancelState(:final items), FailBatchOfItem(:final id)):
        _state.value = WaitingCancelState(
          _updateItemStatus(id, items, BatchItemState.failed),
        );

      case (WaitingCancelState(:final items), CanceledBatchOfItem(:final id)):
        _state.value = WaitingCancelState(
          _updateItemStatus(id, items, BatchItemState.waiting),
        );

      case (WaitingCancelState(:final items), CanceledBatch()):
        _state.value = CanceledState(items);

      case (ProcessingState(:final items), FailedBatch()):
        _state.value = FailedState(items);

      case (ProcessingState(:final items), CompleteBatch()):
        _state.value = DoneState(items);

      default:
        talker.warning(
          'Unknown dispatch request: (${_state.runtimeType}, ${event.runtimeType}})',
        );
    }
  }

  List<BatchItem> _updateItemStatus(
    String id,
    List<BatchItem> items,
    BatchItemState state,
  ) {
    final item = items.firstWhere((i) => i.id == id).copyWith(state: state);
    return items.copyWithItem(item);
  }

  void _fetch() async {
    try {
      final articles = await notion
          .fetchWebArticles()
          .then(notion.parseWebArticles)
          .then(notion.enrichArticlesWithWebTitles);

      final blocks = await articles.asyncMapSequential(
        (fetchedItem) => notion.getBlockChildren(fetchedItem.id),
      );

      final fetchedItems = articles
          .zipWith(
            (article, blocks) => FetchedItem(page: article, blocks: blocks),
            blocks,
          )
          .toList();

      dispatch(FetchSuccess(fetchedItems));
    } catch (_) {
      dispatch(FetchFail());
    }
  }

  void _runBatch(List<BatchItem> items) async {
    for (final item in items.where((i) => i.selected)) {
      if (!_toContinueMainLoop) break;

      dispatch(StartBatchOfItem(id: item.id));

      final result = await processBatchItem(
        item,
        toCancel: () => !_toContinueMainLoop,
      );

      switch (result) {
        case BatchItemResult.canceled:
          dispatch(CanceledBatchOfItem(id: item.id));
        case BatchItemResult.complete:
          dispatch(CompleteBatchOfItem(id: item.id));
        case BatchItemResult.failed:
          dispatch(FailBatchOfItem(id: item.id));
      }
    }

    switch (_state.value) {
      case WaitingCancelState():
        dispatch(CanceledBatch());

      case ProcessingState(:final items):
        if (items.any((item) => item.state == BatchItemState.failed)) {
          dispatch(FailedBatch());
        } else {
          dispatch(CompleteBatch());
        }

      default:
        talker.warning(
          'Unknown state after runBatch: ${_state.value.runtimeType}',
        );
    }
  }

  List<BatchItem> _convertToBatchItems(List<FetchedItem> fetchedItems) =>
      fetchedItems
          .map(
            (item) => BatchItem(
              id: item.page.id,
              title: item.page.title,
              url: item.page.url,
              texts: item.blocks.expand((b) => b.format()).toList(),
              selected: true,
              state: BatchItemState.waiting,
            ),
          )
          .toList();
}

enum BatchItemResult { complete, failed, canceled }

Future<BatchItemResult> processBatchItem(
  BatchItem item, {
  required bool Function() toCancel,
}) async {
  try {
    final sc = await getSummurizedContent(item.texts);
    if (toCancel()) return BatchItemResult.canceled;

    await registForTTS(
      TTSContent(title: item.title, url: item.url, content: sc),
    );
    await notion.markArticleAsProcessed(item.id);
  } catch (e) {
    talker.error('failed to summarize article', e);
    return BatchItemResult.failed;
  }

  return BatchItemResult.complete;
}
