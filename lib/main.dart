import 'package:english_speech/settings_screen.dart';
import 'package:english_speech/web_article_processor_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Speech Article Processor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Batch Process'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Summarize Web Articles'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WebArticleProcessorScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('Summarize YouTube Videos'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DummyScreen(
                    batchName: 'Summarize YouTube Videos',
                    icon: Icons.video_library_outlined,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.multitrack_audio_outlined),
            title: const Text('Create Audio from Summaries'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DummyScreen(
                    batchName: 'Create Audio from Summaries',
                    icon: Icons.multitrack_audio_outlined,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DummyScreen extends StatelessWidget {
  final String batchName;
  final IconData icon;
  const DummyScreen({super.key, required this.batchName, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(batchName, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Center(child: Text('$batchName is not implemented yet.')),
    );
  }
}
