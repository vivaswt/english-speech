import 'package:shared_preferences/shared_preferences.dart';

/// A service class for managing application settings.
///
/// This class abstracts the storage and retrieval of settings, such as
/// API keys, using SharedPreferences.
class SettingsService {
  static const _notionApiKey = 'notion_api_key';
  static const _geminiApiKey = 'gemini_api_key';

  /// Sets the Notion API key.
  Future<void> setNotionApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notionApiKey, key);
  }

  /// Gets the Notion API key. Returns an empty string if not set.
  Future<String> getNotionApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notionApiKey) ?? '';
  }

  /// Sets the Gemini API key.
  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKey, key);
  }

  /// Gets the Gemini API key. Returns an empty string if not set.
  Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKey) ?? '';
  }
}
