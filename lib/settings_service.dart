import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// A service class for managing application settings.
///
/// This class abstracts the storage and retrieval of settings, such as
/// API keys, using SharedPreferences.
class SettingsService {
  static const _notionApiKey = 'notion_api_key';
  static const _geminiApiKey = 'gemini_api_key';
  static const _ttsApiKey = 'tts_api_key';

  // --- Singleton Pattern ---
  SettingsService._();
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  // -------------------------

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Checks if the code is running in a test environment.
  bool _isTestEnvironment() {
    return Platform.environment.containsKey('FLUTTER_TEST');
  }

  /// Sets the Notion API key.
  Future<void> setNotionApiKey(String key) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_notionApiKey, key);
  }

  /// Gets the Notion API key. Returns an empty string if not set.
  Future<String> getNotionApiKey() async {
    if (_isTestEnvironment()) {
      return Platform.environment['NOTION_API_KEY'] ?? '';
    }
    final prefs = await _prefsInstance;
    return prefs.getString(_notionApiKey) ?? '';
  }

  /// Sets the Gemini API key.
  Future<void> setGeminiApiKey(String key) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_geminiApiKey, key);
  }

  /// Gets the Gemini API key. Returns an empty string if not set.
  Future<String> getGeminiApiKey() async {
    if (_isTestEnvironment()) {
      return Platform.environment['GEMINI_API_KEY'] ?? '';
    }
    final prefs = await _prefsInstance;
    return prefs.getString(_geminiApiKey) ?? '';
  }

  /// Sets the TTS API key.
  Future<void> setTtsApiKey(String key) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_ttsApiKey, key);
  }

  /// Gets the TTS API key. Returns an empty string if not set.
  Future<String> getTtsApiKey() async {
    if (_isTestEnvironment()) {
      return Platform.environment['TTS_API_KEY'] ?? '';
    }
    final prefs = await _prefsInstance;
    return prefs.getString(_ttsApiKey) ?? '';
  }
}
