import 'package:english_speech/batch/manual_summary_selection_batch.dart';
import 'package:english_speech/extension/widget_wrap.dart';
import 'package:english_speech/google/youtube.dart';
import 'package:english_speech/screen/manual_summary_register_screen.dart';
import 'package:flutter/material.dart';

class ManualSummarySelectScreen extends StatefulWidget {
  const ManualSummarySelectScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ManualSummarySelectScreenState();
}

class _ManualSummarySelectScreenState extends State<ManualSummarySelectScreen> {
  final Batch _batch = Batch();

  @override
  void initState() {
    super.initState();
    _batch.dispatch(Fetch());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.note_alt_outlined),
          SizedBox(width: 8),
          Text('Manually Summarize Articles'),
        ],
      ),
    ),
    body: ValueListenableBuilder(
      valueListenable: _batch.state,
      builder: (context, state, child) => switch (state) {
        InitState() => const Center(child: Text('Initializing...')),

        FetchingState() => [
          Text('Fetching...'),
          CircularProgressIndicator(),
        ].wrapWithColumn().wrapWithCenter(),

        FailToFetchState() => const Center(child: Text('Failed to fetch.')),

        SelectingItemsState(:final items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.title),
                leading: Image(
                  image: NetworkImage(getThumbnailUrl(item.url)),
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.device_unknown),
                ),
                trailing: ItemStateIcon(item.state),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute<BatchItem>(
                      builder: (context) =>
                          ManualSummaryRegisterScreen(item: item),
                    ),
                  );
                  if (result == null) return;

                  _batch.dispatch(ItemStateChangted(item.id, result.state));
                },
              ),
            );
          },
        ),
      },
    ),
  );
}

class ItemStateIcon extends StatelessWidget {
  final BatchItemState _state;

  const ItemStateIcon(this._state, {super.key});

  @override
  Widget build(BuildContext context) => switch (_state) {
    BatchItemState.waiting => const Icon(Icons.schedule, color: Colors.grey),
    BatchItemState.done => const Icon(Icons.check_circle, color: Colors.green),
  };
}
