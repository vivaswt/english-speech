import 'package:english_speech/service/log.dart';
import 'package:flutter/material.dart';
import 'package:english_speech/notion/notion_web_articles.dart' as notion;

// --- States ---
sealed class BatchState {}

class InitState extends BatchState {}

class FetchingState extends BatchState {}

class FailToFetchState extends BatchState {}

class SelectingItemsState extends BatchState {
  final List<BatchItem> items;

  SelectingItemsState(this.items);
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

class ItemStateChangted extends BatchEvent {
  final String id;
  final BatchItemState itemState;

  ItemStateChangted(this.id, this.itemState);
}

// --- Data ---
typedef FetchedItem = notion.WebArticlesPage;

class BatchItem {
  final String id;
  final String title;
  final String url;
  final BatchItemState state;

  BatchItem({
    required this.id,
    required this.title,
    required this.url,
    required this.state,
  });

  BatchItem copyWith({BatchItemState? state}) =>
      BatchItem(id: id, title: title, url: url, state: state ?? this.state);
}

enum BatchItemState { waiting, done }

class Batch {
  final ValueNotifier<BatchState> _state = ValueNotifier(InitState());

  ValueNotifier<BatchState> get state => _state;

  Future<void> dispatch(BatchEvent event) async {
    switch ((_state.value, event)) {
      case (InitState(), Fetch()):
        _state.value = FetchingState();
        _fetch();

      case (FetchingState(), FetchSuccess(:final items)):
        final batchItems = _convertToBatchItems(items);
        _state.value = SelectingItemsState(batchItems);

      case (
        SelectingItemsState(:final items),
        ItemStateChangted(:final id, :final itemState),
      ):
        final batchItems = items
            .map(
              (item) => item.id == id ? item.copyWith(state: itemState) : item,
            )
            .toList();
        _state.value = SelectingItemsState(batchItems);

      default:
        talker.warning(
          'Unknown dispatch request: (${_state.value.runtimeType}, ${event.runtimeType}})',
        );
    }
  }

  Future<void> _fetch() async {
    try {
      final articles = await notion
          .fetchWebArticles()
          .then(notion.parseWebArticles)
          .then(notion.enrichArticlesWithWebTitles);

      dispatch(FetchSuccess(articles));
    } catch (e) {
      talker.error('failed to fetch articles', e);
      dispatch(FetchFail());
    }
  }

  List<BatchItem> _convertToBatchItems(List<FetchedItem> fetchedItems) =>
      fetchedItems
          .map(
            (item) => BatchItem(
              id: item.id,
              title: item.title,
              url: item.url,
              state: BatchItemState.waiting,
            ),
          )
          .toList();
}
