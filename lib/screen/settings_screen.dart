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

  @override
  void initState() {
    super.initState();
    _notionApiKeyController = TextEditingController();
    _geminiApiKeyController = TextEditingController();
    _loadSettings();

    // Add listeners to save the values as the user types.
    _notionApiKeyController.addListener(() {
      _settingsService.setNotionApiKey(_notionApiKeyController.text);
    });
    _geminiApiKeyController.addListener(() {
      _settingsService.setGeminiApiKey(_geminiApiKeyController.text);
    });
  }

  Future<void> _loadSettings() async {
    _notionApiKeyController.text = await _settingsService.getNotionApiKey();
    _geminiApiKeyController.text = await _settingsService.getGeminiApiKey();
  }

  @override
  void dispose() {
    _notionApiKeyController.dispose();
    _geminiApiKeyController.dispose();
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
}
