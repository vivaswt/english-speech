import 'package:english_speech/gemini.dart';
import 'package:english_speech/notion_contents_for_tts.dart';
import 'package:english_speech/notion_web_articles.dart' as notion;
import 'package:english_speech/settings_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

enum ProcessState { fetching, processing, waitCancel, done, failed }

enum ArticleProcessState { waiting, processing, done, failed }

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ProcessState _processState = ProcessState.done;
  List<notion.WebArticlesPage> _articles = []; // Changed from String to List
  List<ArticleProcessState> _articleProcessStates = [];
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
              articleProcessStates: _articleProcessStates,
              errorMessage: _errorMessage,
              processState: _processState,
              onButtonPressed: buttonPressed,
              onCancelPressed: cancelPressed,
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

      final articleProcessStates = List.generate(
        articles.length,
        (_) => ArticleProcessState.waiting,
      );

      setState(() {
        _articles = articles; // Store articles directly
        _processState = ProcessState.processing;
        _articleProcessStates = articleProcessStates;
      });

      await processArticles().whenComplete(handleProcessCompletion);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _processState = ProcessState.failed;
      });
    }
  }

  void cancelPressed() async {
    setState(() {
      _processState = ProcessState.waitCancel;
    });
  }

  void handleProcessCompletion() {
    if (!mounted) return;

    if (_processState == ProcessState.waitCancel) {
      // If cancelled, revert the 'processing' item back to 'waiting'
      final processingIndex = _articleProcessStates.indexWhere(
        (s) => s == ArticleProcessState.processing,
      );
      if (processingIndex != -1) {
        _articleProcessStates[processingIndex] = ArticleProcessState.waiting;
      }
    }

    setState(() => _processState = ProcessState.done);
  }

  Future<void> processArticles() async {
    for (int i = 0; i < _articles.length; i++) {
      setState(() {
        // Set current article to processing
        _articleProcessStates[i] = ArticleProcessState.processing;
      });

      final page = _articles[i];

      try {
        if (_processState == ProcessState.waitCancel) break;
        final bs = await notion.getBlockChildren(page.id);

        if (_processState == ProcessState.waitCancel) break;
        final sc = await getSummurizedContent(
          bs.expand((b) => b.format()).toList(),
        );

        if (_processState == ProcessState.waitCancel) break;
        await registForTTS(title: page.title, url: page.url, content: sc);
        await notion.markArticleAsProcessed(page.id);

        setState(() {
          _articleProcessStates[i] = ArticleProcessState.done;
        });
      } catch (e) {
        setState(() {
          _articleProcessStates[i] = ArticleProcessState.failed;
        });
      }
    }
  }
}

// Separate widget class for reusable component
class DataDisplayScreen extends StatelessWidget {
  final List<notion.WebArticlesPage> articles; // Changed from String to List
  final String? errorMessage;
  final ProcessState processState;
  final VoidCallback onButtonPressed;
  final VoidCallback onCancelPressed;
  final List<ArticleProcessState> articleProcessStates;

  const DataDisplayScreen({
    super.key,
    required this.articles,
    this.errorMessage,
    required this.processState,
    required this.onButtonPressed,
    required this.onCancelPressed,
    required this.articleProcessStates,
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
        final articleState = articleProcessStates[index];

        Widget trailingIcon;
        switch (articleState) {
          case ArticleProcessState.waiting:
            trailingIcon = const Icon(Icons.schedule, color: Colors.grey);
            break;
          case ArticleProcessState.processing:
            trailingIcon = const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            );
            break;
          case ArticleProcessState.done:
            trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
            break;
          case ArticleProcessState.failed:
            trailingIcon = const Icon(Icons.error, color: Colors.red);
            break;
        }

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
            trailing: trailingIcon,
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: switch (processState) {
          ProcessState.done => onButtonPressed,
          ProcessState.fetching => null,
          ProcessState.processing => onCancelPressed,
          ProcessState.waitCancel => null,
          ProcessState.failed => null,
        },
        child: Text(switch (processState) {
          ProcessState.done => 'Run',
          ProcessState.fetching => 'Fetching...',
          ProcessState.processing => 'Cancel',
          ProcessState.waitCancel => 'Waiting to cancel...',
          ProcessState.failed => 'Failed',
        }),
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
