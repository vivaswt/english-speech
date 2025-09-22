import 'package:english_speech/batch/tts.dart';
import 'package:english_speech/settings_service.dart';
import 'package:flutter/material.dart';

class TtsCreationScreen extends StatefulWidget {
  const TtsCreationScreen({super.key});

  @override
  State<TtsCreationScreen> createState() => _TtsCreationScreenState();
}

class _TtsCreationScreenState extends State<TtsCreationScreen> {
  late final TtsBatch _ttsBatch;

  @override
  void initState() {
    super.initState();
    _ttsBatch = TtsBatch()..addListener(_onBatchUpdate);
    // Automatically start fetching data when the screen is initialized.
    _ttsBatch.selectData();
  }

  void _onBatchUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _ttsBatch.removeListener(_onBatchUpdate);
    _ttsBatch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.multitrack_audio_outlined),
            SizedBox(width: 8),
            Text('Create Audio from Summaries'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          const SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_ttsBatch.status == BatchStatus.selectingData &&
        _ttsBatch.contents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ttsBatch.contents.isEmpty) {
      return const Center(
        child: Text(
          'No summaries found to create audio from.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ttsBatch.contents.length,
      itemBuilder: (context, index) {
        final content = _ttsBatch.contents[index];
        final itemStatus = _ttsBatch.itemStatuses[index];

        Widget trailingIcon = itemStatus.when(
          waiting: () => const Icon(Icons.schedule, color: Colors.grey),
          processing: (_, progress) => SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress, // Use the progress value here
              strokeWidth: 3,
            ),
          ),
          done: () => const Icon(Icons.check_circle, color: Colors.green),
          failed: (_, message) => const Icon(Icons.error, color: Colors.red),
          orElse: () => const SizedBox.shrink(),
        );

        return Card(
          child: ListTile(
            title: Text(content.title),
            subtitle: itemStatus.when(
              processing: (processingName, _) => Text(
                processingName,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              failed: (_, message) =>
                  Text(message, style: const TextStyle(color: Colors.red)),
              orElse: () => Text(
                'Lines: ${content.countOfWords} words',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            trailing: trailingIcon,
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    final status = _ttsBatch.status;

    final VoidCallback? onPressed = switch (status) {
      BatchStatus.waitToStart => () => _ttsBatch.start(
        // TtsApiSelection.googleCloud,
        TtsApiSelection.gemini,
      ),
      BatchStatus.processing => _ttsBatch.cancel,
      _ => null,
    };

    final String buttonText = switch (status) {
      BatchStatus.init => 'Initializing...',
      BatchStatus.selectingData => 'Fetching Summaries...',
      BatchStatus.waitToStart => 'Run',
      BatchStatus.processing => 'Cancel',
      BatchStatus.waitToBeCancelled => 'Cancelling...',
      BatchStatus.cancelled => 'Cancelled',
      BatchStatus.completed => 'Completed',
      BatchStatus.failed => 'Failed',
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
        child: Text(buttonText),
      ),
    );
  }
}
