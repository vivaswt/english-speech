import 'package:english_speech/settings_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsService = SettingsService();
  late final TextEditingController _notionApiKeyController;
  late final TextEditingController _geminiApiKeyController;
  late final TextEditingController _ttsApiKeyController;
  double _speakingRate = 1.0; // Default value

  @override
  void initState() {
    super.initState();
    _notionApiKeyController = TextEditingController();
    _geminiApiKeyController = TextEditingController();
    _ttsApiKeyController = TextEditingController();
    _loadSettings();

    // Add listeners to save the values as the user types.
    _notionApiKeyController.addListener(() {
      _settingsService.setNotionApiKey(_notionApiKeyController.text);
    });
    _geminiApiKeyController.addListener(() {
      _settingsService.setGeminiApiKey(_geminiApiKeyController.text);
    });
    _ttsApiKeyController.addListener(() {
      _settingsService.setTtsApiKey(_ttsApiKeyController.text);
    });
  }

  Future<void> _loadSettings() async {
    _notionApiKeyController.text = await _settingsService.getNotionApiKey();
    _geminiApiKeyController.text = await _settingsService.getGeminiApiKey();
    _speakingRate = await _settingsService.getSpeakingRate();
    _ttsApiKeyController.text = await _settingsService.getTtsApiKey();
    // Rebuild the widget to reflect the loaded speaking rate.
    setState(() {});
  }

  @override
  void dispose() {
    _notionApiKeyController.dispose();
    _geminiApiKeyController.dispose();
    _ttsApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(
              controller: _notionApiKeyController,
              labelText: 'Notion API Key',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _geminiApiKeyController,
              labelText: 'Gemini API Key',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ttsApiKeyController,
              labelText: 'Google TTS API Key',
            ),
            const SizedBox(height: 24),
            _buildSpeakingRateSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      obscureText: true, // API keys should be obscured for security.
    );
  }

  Widget _buildSpeakingRateSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speaking Rate: ${_speakingRate.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _speakingRate,
          min: 0.3,
          max: 2.0,
          divisions: 17, // (2.0 - 0.3) / 0.1 = 17
          label: _speakingRate.toStringAsFixed(1),
          onChanged: (double value) {
            setState(() {
              _speakingRate = value;
            });
            // Save the value immediately.
            _settingsService.setSpeakingRate(value);
          },
        ),
      ],
    );
  }
}
