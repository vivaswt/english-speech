import 'package:english_speech/batch/summarize.dart';
import 'package:english_speech/extension/widget_wrap.dart';
import 'package:flutter/material.dart';

class ArticleSummarizerScreen extends StatefulWidget {
  const ArticleSummarizerScreen({super.key});

  @override
  State<ArticleSummarizerScreen> createState() =>
      _ArticleSummarizerScreenState();
}

class _ArticleSummarizerScreenState extends State<ArticleSummarizerScreen> {
  final Batch _batch = Batch();

  @override
  void initState() {
    super.initState();
    _batch.dispatch(Fetch());
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _batch.state,
    builder: (context, state, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Summarize Articles'),
          actions: _appBarActions(context, state),
          actionsPadding: const EdgeInsets.only(right: 24),
        ),
        body: switch (state) {
          InitState() => const Center(child: Text('Initializing...')),

          FetchingState() => [
            Text('Fetching...'),
            CircularProgressIndicator(),
          ].wrapWithColumn(),

          FailToFetchState() => const Center(child: Text('Failed to fetch.')),

          SelectingItemsState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: true,
            onSelectedChanged: (id, value) =>
                _batch.dispatch(SelectItem(id: id, selected: value)),
            message: 'Select the articles you want to summarize.',
          ),

          ProcessingState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: false,
            onSelectedChanged: (_, _) {},
            message: 'Proccesing...',
          ),

          WaitingCancelState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: false,
            onSelectedChanged: (_, _) {},
            message: 'Waiting to cancel...',
          ),

          DoneState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: false,
            onSelectedChanged: (_, _) {},
            message: 'All ariticles have been summarized.',
          ),

          CanceledState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: false,
            onSelectedChanged: (_, _) {},
            message: 'The process is canceled.',
          ),

          FailedState(:final items) => BatchEditingView(
            batchItems: items,
            selectionEnabled: false,
            onSelectedChanged: (_, _) {},
            message: 'Failed to summarize an article and stopped.',
          ),
        },
      );
    },
  );

  List<Widget> _appBarActions(BuildContext context, BatchState state) =>
      switch (state) {
        SelectingItemsState() => [
          IconButton(
            onPressed: () => _batch.dispatch(SelectAllItems()),
            icon: Icon(Icons.select_all),
            tooltip: 'Select All',
          ),
          IconButton(
            onPressed: () => _batch.dispatch(DeselectAllItems()),
            icon: Icon(Icons.deselect),
            tooltip: 'Deselect All',
          ),
          IconButton(
            onPressed: () => _batch.dispatch(RunBatch()),
            icon: Icon(
              Icons.play_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Run Batch',
          ),
        ],
        ProcessingState() => [
          IconButton(
            onPressed: () => _batch.dispatch(CancelBatch()),
            icon: Icon(Icons.stop_circle),
            tooltip: 'Cancel Batch',
          ),
        ],
        _ => [],
      };
}

class BatchEditingView extends StatelessWidget {
  final List<BatchItem> _batchItems;
  final void Function(String, bool) _onSelectedChanged;
  final bool _selectionEnabled;
  final String? _message;

  const BatchEditingView({
    super.key,
    required List<BatchItem> batchItems,
    required bool selectionEnabled,
    required void Function(String, bool) onSelectedChanged,
    String? message,
  }) : _batchItems = batchItems,
       _selectionEnabled = selectionEnabled,
       _onSelectedChanged = onSelectedChanged,
       _message = message;

  @override
  Widget build(BuildContext context) => [
    ListView.builder(
      itemCount: _batchItems.length,
      itemBuilder: (context, index) {
        final item = _batchItems[index];
        return CheckboxListTile(
          value: item.selected,
          onChanged: _selectionEnabled
              ? (value) => _onSelectedChanged(item.id, value!)
              : null,
          title: Text(item.title),
          secondary: ItemStateIcon(item.state),
        );
      },
    ).wrapWithExpanded(),

    Text(_message ?? 'no message'),
  ].wrapWithColumn();
}

class ItemStateIcon extends StatelessWidget {
  final BatchItemState _state;

  const ItemStateIcon(this._state, {super.key});

  @override
  Widget build(BuildContext context) {
    final iconSize = IconTheme.of(context).size;
    return switch (_state) {
      BatchItemState.waiting => const Icon(Icons.schedule, color: Colors.grey),
      BatchItemState.processing => SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
      BatchItemState.done => const Icon(
        Icons.check_circle,
        color: Colors.green,
      ),
      BatchItemState.failed => const Icon(Icons.error, color: Colors.red),
    };
  }
}
