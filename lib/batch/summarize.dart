// --- States ---
import 'package:english_speech/service/log.dart';
import 'package:flutter/material.dart';

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
  final String id;
  final String title;
  final List<String> texts;

  FetchedItem({required this.id, required this.title, required this.texts});
}

enum BatchItemState { waiting, processing, done, failed }

class BatchItem {
  final String id;
  final String title;
  final List<String> texts;
  final bool selected;
  final BatchItemState state;
  BatchItem({
    required this.id,
    required this.title,
    required this.texts,
    required this.selected,
    required this.state,
  });

  BatchItem copyWith({bool? selected, BatchItemState? state}) => BatchItem(
    id: id,
    title: title,
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
      await Future.delayed(Duration(seconds: 2));
      dispatch(FetchSuccess(_getDummyFetchedItems()));
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
          break;
        case BatchItemResult.complete:
          dispatch(CompleteBatchOfItem(id: item.id));
        case BatchItemResult.failed:
          dispatch(FailBatchOfItem(id: item.id));
          break;
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
              id: item.id,
              title: item.title,
              texts: item.texts,
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
  if (toCancel()) return BatchItemResult.canceled;
  await Future.delayed(Duration(milliseconds: 500));

  if (toCancel()) return BatchItemResult.canceled;
  await Future.delayed(Duration(milliseconds: 500));

  return BatchItemResult.complete;
}

List<FetchedItem> _getDummyFetchedItems() => [
  FetchedItem(
    id: '48291056',
    title: '2026年、最新ガジェット10選',
    texts: [
      '今年のトレンドは「完全自動化」です。',
      '特にAIを搭載したスマートウォッチが市場を席巻しています。',
      '生活を劇的に変えるデバイスを詳しく紹介します。',
    ],
  ),
  FetchedItem(
    id: '10923847',
    title: '初心者でも失敗しない！週末キャンプの極意',
    texts: [
      '最近のキャンプブームで、手軽な「手ぶらキャンプ」が人気です。',
      'まずは近場のキャンプ場から始めるのがおすすめ。',
      '必要な装備と注意点をまとめました。',
    ],
  ),
  FetchedItem(
    id: '77342109',
    title: '話題のカフェ「Blue Moon」潜入レポート',
    texts: [
      '表参道にオープンしたばかりのカフェに行ってきました。',
      '一番人気の「雲色ラテ」は見た目も味も最高。',
      '店内は落ち着いた雰囲気で、リモートワークにも最適です。',
    ],
  ),
  FetchedItem(
    id: '55610293',
    title: '効率的なプログラミング学習法',
    texts: [
      '独学で挫折しないためには、アウトプットが重要です。',
      '毎日15分でもいいのでコードを書く習慣をつけましょう。',
      'おすすめのオンライン教材も併せて解説します。',
    ],
  ),
  FetchedItem(
    id: '22904817',
    title: '自宅でできる！簡単ストレッチ習慣',
    texts: [
      'デスクワークで固まった肩や腰をほぐしませんか？',
      '座ったまま5分でできるエクササイズを紹介します。',
      '継続することで基礎代謝の向上も期待できます。',
    ],
  ),
  FetchedItem(
    id: '88127340',
    title: '宇宙旅行がもっと身近に？最新の民間ロケット開発',
    texts: [
      '大手テック企業による宇宙開発競争が加速しています。',
      '来年には一般向けの月周回旅行も計画されているとのこと。',
      '夢の話だった宇宙旅行がいよいよ現実味を帯びてきました。',
    ],
  ),
  FetchedItem(
    id: '33495821',
    title: '【書評】心の整理術：マインドフルネスの力',
    texts: [
      '現代社会のストレスから解放されるためのヒントが詰まった一冊。',
      'マインドフルネスを日常に取り入れる具体的な方法が書かれています。',
      '忙しいビジネスマンにこそ読んでほしい内容です。',
    ],
  ),
  FetchedItem(
    id: '66201984',
    title: '旬の食材を使った「春の彩りパスタ」レシピ',
    texts: [
      'アスパラガスと桜エビを贅沢に使った春らしい一皿です。',
      'オリーブオイルの香りが食欲をそそります。',
      '15分で作れるので、忙しい日の夕食にもぴったり。',
    ],
  ),
];
