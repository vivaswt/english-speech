import 'package:english_speech/notion_web_articles.dart' as notion;
import 'package:english_speech/settings_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

enum ProcessState { fetching, done, failed }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ProcessState _processState = ProcessState.done;
  List<notion.WebArticlesPage> _articles = []; // Changed from String to List
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          // This context is below MaterialApp and can find the Navigator.
          return Scaffold(
            appBar: AppBar(
              title: const Text('English Speech Articles'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: DataDisplayScreen(
              articles: _articles, // Changed from fetchedData to articles
              errorMessage: _errorMessage,
              processState: _processState,
              onButtonPressed: buttonPressed,
            ),
          );
        },
      ),
    );
  }

  void buttonPressed() async {
    setState(() {
      _processState = ProcessState.fetching;
      _errorMessage = null;
    });
    try {
      final articles = await notion
          .fetchWebArticles()
          .then(notion.parseWebArticles)
          .then(notion.enrichArticlesWithWebTitles);

      setState(() {
        _articles = articles; // Store articles directly
        _processState = ProcessState.done;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _processState = ProcessState.failed;
      });
    }
  }
}

// Separate widget class for reusable component
class DataDisplayScreen extends StatelessWidget {
  final List<notion.WebArticlesPage> articles; // Changed from String to List
  final String? errorMessage;
  final ProcessState processState;
  final VoidCallback onButtonPressed;

  const DataDisplayScreen({
    super.key,
    required this.articles,
    this.errorMessage,
    required this.processState,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildContent()),
        const SizedBox(height: 16),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildContent() {
    if (processState == ProcessState.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            errorMessage ?? 'An unknown error occurred.',
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (processState == ProcessState.fetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (articles.isEmpty) {
      return const Center(
        child: Text(
          'Press "Run" to fetch articles.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Card(
          child: ListTile(
            title: Text(article.title),
            subtitle: Text('ID: ${article.id}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleContentsScreen(
                    articleId: article.id,
                    articleTitle: article.title,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: processState == ProcessState.fetching
            ? null
            : onButtonPressed,
        child: Text(
          processState == ProcessState.fetching ? 'Loading...' : 'Run',
        ),
      ),
    );
  }
}

class ArticleContentsScreen extends StatefulWidget {
  final String articleId;
  final String articleTitle;

  const ArticleContentsScreen({
    super.key,
    required this.articleId,
    required this.articleTitle,
  });

  @override
  State<ArticleContentsScreen> createState() => _ArticleContentsScreenState();
}

class _ArticleContentsScreenState extends State<ArticleContentsScreen> {
  late Future<List<notion.Block>> _contentsFuture;

  @override
  void initState() {
    super.initState();
    _contentsFuture = notion.getBlockChildren(widget.articleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.articleTitle)),
      body: Builder(
        // Use a Builder to get a context below the Scaffold
        builder: (BuildContext scaffoldContext) {
          return FutureBuilder<List<notion.Block>>(
            future: _contentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText(
                  snapshot.data == null
                      ? 'No content available.'
                      : formattedBlocks(snapshot.data!).join('\n'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

List<String> formattedBlocks(List<notion.Block> blocks) => blocks
    .expand((b) => [...b.format(), ...formattedBlocks(b.children)])
    .toList();
