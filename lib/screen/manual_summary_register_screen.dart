import 'package:english_speech/batch/manual_summary_selection_batch.dart' as s;
import 'package:english_speech/extension/widget_wrap.dart';
import 'package:english_speech/google/gemini.dart';
import 'package:english_speech/google/youtube.dart';
import 'package:english_speech/notion/notion_contents_for_tts.dart';
import 'package:english_speech/service/log.dart';
import 'package:flutter/material.dart';
import 'package:english_speech/notion/notion_web_articles.dart' as notion;
import 'package:flutter/services.dart';

class ManualSummaryRegisterScreen extends StatefulWidget {
  final s.BatchItem item;
  const ManualSummaryRegisterScreen({super.key, required this.item});

  @override
  State<StatefulWidget> createState() => _ManualSummaryRegisterScreenState();
}

class _ManualSummaryRegisterScreenState
    extends State<ManualSummaryRegisterScreen> {
  final ValueNotifier<ViewState> _viewStateNotifier = ValueNotifier(
    LoadingState(),
  );
  final TextEditingController _summaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _summaryController.addListener(_onSummaryChanged);

    _fetchArticleTexts(widget.item.id);
  }

  @override
  void dispose() {
    _summaryController.removeListener(_onSummaryChanged);
    _summaryController.dispose();
    _viewStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ManualSummaryRegisterAppBar(
      viewStateNotifier: _viewStateNotifier,
      register: () => _register(context),
    ),
    body:
        [
              ValueListenableBuilder(
                valueListenable: _viewStateNotifier,
                builder: (context, viewState, child) {
                  return ManualSummaryRegisterHeader(
                    title: widget.item.title,
                    url: widget.item.url,
                    viewState: viewState,
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: _viewStateNotifier,
                builder: (context, viewState, child) {
                  return TextField(
                    controller: _summaryController,
                    enabled: viewState.canEditSummary,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Summary'),
                    ),
                  ).wrapWithExpanded();
                },
              ),
              ValueListenableBuilder(
                valueListenable: _viewStateNotifier,
                builder: (context, viewState, child) =>
                    ManualSummaryRegisterMessage(viewState: viewState),
              ),
            ]
            .wrapWithColumn(spacing: 8)
            .wrapWithPadding(padding: const EdgeInsets.all(8)),
  );

  Future<void> _fetchArticleTexts(String pageID) async {
    final blocks = await notion.getBlockChildren(pageID);
    final prompt =
        summarizeInstruction +
        '\n' +
        blocks.expand((b) => b.format()).join(' ');

    if (!mounted) return;

    _viewStateNotifier.value = WaitingSummaryState(prompt: prompt);
  }

  Future<void> _register(BuildContext context) async {
    switch (_viewStateNotifier.value) {
      case ReadyToRegisterState(:final prompt):
        _viewStateNotifier.value = RegisteringState(prompt: prompt);

        try {
          final content = _summaryController.text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();

          await registForTTS(
            TTSContent(
              title: widget.item.title,
              url: widget.item.url,
              content: content,
            ),
          );

          await notion.markArticleAsProcessed(widget.item.id);

          if (mounted) {
            Navigator.pop(
              context,
              widget.item.copyWith(state: s.BatchItemState.done),
            );
          }
        } catch (e) {
          talker.error('failed to register summarized article', e);
          _viewStateNotifier.value = ErrorState(
            prompt: prompt,
            message: 'failed to register summarized article',
          );
        }

      default:
        talker.warning(
          'unknown view state ${_viewStateNotifier.value.runtimeType}',
        );
    }
  }

  void _onSummaryChanged() {
    final summary = _summaryController.text;

    switch (_viewStateNotifier.value) {
      case WaitingSummaryState(:final prompt):
        if (summary.isNotEmpty) {
          _viewStateNotifier.value = ReadyToRegisterState(prompt: prompt);
        }

      case ReadyToRegisterState(:final prompt):
        if (summary.isEmpty) {
          _viewStateNotifier.value = WaitingSummaryState(prompt: prompt);
        }

      default:
    }
  }
}

class ManualSummaryRegisterMessage extends StatelessWidget {
  final ViewState _viewState;

  const ManualSummaryRegisterMessage({super.key, required ViewState viewState})
    : _viewState = viewState;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: switch (_viewState) {
      LoadingState() => const Text('Loading...'),
      WaitingSummaryState() => const Text(
        'Copy the prompt, request AI to summarize and paste it here',
      ),
      ReadyToRegisterState() => const Text('Click Register button to register'),
      RegisteringState() => const Text('Registering...'),
      ErrorState(:final message) => Text('Error: $message'),
    },
  );
}

class ManualSummaryRegisterHeader extends StatelessWidget {
  final String title;
  final String url;
  final ViewState viewState;

  const ManualSummaryRegisterHeader({
    super.key,
    required this.title,
    required this.url,
    required this.viewState,
  });

  @override
  Widget build(BuildContext context) => [
    Image(
      image: NetworkImage(getThumbnailUrl(url)),
      errorBuilder: (context, error, stackTrace) => Icon(Icons.device_unknown),
    ).wrapWithSizedBox(height: 48),
    Text(title).wrapWithExpanded(),
    CopyPromptButton(viewState: viewState),
  ].wrapWithRow(crossAxisAlignment: CrossAxisAlignment.center, spacing: 8);
}

class CopyPromptButton extends StatelessWidget {
  final ViewState viewState;

  const CopyPromptButton({super.key, required this.viewState});

  @override
  Widget build(BuildContext context) => switch (viewState) {
    WaitingSummaryState(:final prompt) ||
    ReadyToRegisterState(:final prompt) ||
    RegisteringState(:final prompt) ||
    ErrorState(:final prompt) => IconButton(
      onPressed: () => _copyPrompt(context, prompt),
      icon: const Icon(Icons.copy),
      tooltip: 'Copy Prompt',
    ),
    LoadingState() => CircularProgressIndicator(),
  };

  Future<void> _copyPrompt(BuildContext context, String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: const Text('Copied to clipboard')));
  }
}

class ManualSummaryRegisterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ValueNotifier<ViewState> _viewStateNotifier;
  final Future<void> Function() _register;

  const ManualSummaryRegisterAppBar({
    super.key,
    required viewStateNotifier,
    required register,
  }) : _viewStateNotifier = viewStateNotifier,
       _register = register;

  @override
  Widget build(BuildContext context) => AppBar(
    title: const Row(
      children: [
        Icon(Icons.note_alt_outlined),
        SizedBox(width: 8),
        Text('Manually Summarize Articles Register'),
      ],
    ),
    actions: [
      ValueListenableBuilder(
        valueListenable: _viewStateNotifier,
        builder: (context, viewState, child) {
          return IconButton(
            icon: Icon(Icons.cloud_upload),
            onPressed: viewState.canRegister ? _register : null,
            tooltip: 'Register',
          );
        },
      ),
    ],
    actionsPadding: const EdgeInsets.only(right: 24),
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

sealed class ViewState {
  bool get canRegister => false;
  bool get canEditSummary => false;
}

class LoadingState extends ViewState {}

class WaitingSummaryState extends ViewState {
  final String prompt;

  WaitingSummaryState({required this.prompt});

  @override
  bool get canEditSummary => true;
}

class ReadyToRegisterState extends ViewState {
  final String prompt;

  ReadyToRegisterState({required this.prompt});

  @override
  bool get canRegister => true;

  @override
  bool get canEditSummary => true;
}

class RegisteringState extends ViewState {
  final String prompt;

  RegisteringState({required this.prompt});
}

class ErrorState extends ViewState {
  final String prompt;
  final String message;

  ErrorState({required this.prompt, required this.message});

  @override
  bool get canRegister => true;

  @override
  bool get canEditSummary => true;
}
