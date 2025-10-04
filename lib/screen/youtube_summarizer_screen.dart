import 'package:english_speech/batch/youtube.dart';
import 'package:english_speech/google/youtube.dart';
import 'package:flutter/material.dart';

class YouTubeSummarizerScreen extends StatefulWidget {
  const YouTubeSummarizerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _YouTubeSummarizerScreenState();
}

class _YouTubeSummarizerScreenState extends State<YouTubeSummarizerScreen> {
  late final YouTubeBatch _batch;

  @override
  void initState() {
    super.initState();
    _batch = YouTubeBatch();
    _batch.addListener(_onBatchUpdate);
  }

  void _onBatchUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _batch.removeListener(_onBatchUpdate);
    _batch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.video_library_outlined),
            SizedBox(width: 8),
            Text('Summarize YouTube Videos'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          const SizedBox(height: 16),
          _buildPlaylistSelector(),
          const SizedBox(height: 16),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_batch.batchStatus == BatchStatus.selectingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_batch.batchItems.isEmpty) {
      return const Center(
        child: Text(
          'No videos found in your playlist.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _batch.batchItems.length,
      itemBuilder: (context, index) {
        final item = _batch.batchItems[index];
        return Card(
          child: ListTile(
            leading: _leading(item.thumbnailUrl),
            title: Text(item.title),
            subtitle: _subtitle(item.itemStatus),
            trailing: _trailingIcon(item.itemStatus),
          ),
        );
      },
    );
  }

  Widget _leading(String? thumbnailUrl) => thumbnailUrl != null
      ? Image.network(thumbnailUrl)
      : const SizedBox.shrink();

  Widget _subtitle(ItemStatus status) => status.when(
    failed: (message) =>
        Text(message, style: const TextStyle(color: Colors.red)),
    orElse: () => const SizedBox.shrink(),
  );

  Widget _trailingIcon(ItemStatus status) => status.when(
    waiting: () => const Icon(Icons.schedule, color: Colors.grey),
    processing: () => CircularProgressIndicator(),
    done: () => const Icon(Icons.check_circle, color: Colors.green),
    failed: (_) => const Icon(Icons.error, color: Colors.red),
    orElse: () => const SizedBox.shrink(),
  );

  Widget _buildActionButton() {
    final status = _batch.batchStatus;

    final VoidCallback? onPressed = switch (status) {
      BatchStatus.waitToStart => _batch.start,
      BatchStatus.processing => _batch.cancel,
      _ => null,
    };

    final String buttonText = switch (status) {
      BatchStatus.initializing => 'Initializing...',
      BatchStatus.selectingData => 'Fetching PlayList Items...',
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

  Widget _buildPlaylistSelector() {
    // Disable the dropdown if there are no playlists or if a batch is running.
    final bool isEnabled =
        _batch.playLists.isNotEmpty &&
        (_batch.batchStatus == BatchStatus.waitToStart ||
            _batch.batchStatus == BatchStatus.completed ||
            _batch.batchStatus == BatchStatus.cancelled);

    if (_batch.playLists.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no playlists are loaded
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<PlayList>(
        decoration: const InputDecoration(
          labelText: 'Select a Playlist',
          border: OutlineInputBorder(),
        ),
        initialValue: _batch.selectedPlayList,
        items: _batch.playLists.map((playlist) {
          return DropdownMenuItem<PlayList>(
            value: playlist,
            child: Text(playlist.title),
          );
        }).toList(),
        onChanged: isEnabled
            ? (playlist) => _batch.selectedPlayList = playlist!
            : null,
      ),
    );
  }
}
