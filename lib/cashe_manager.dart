import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CacheManager {
  // Method to get the file path for a given cache key.
  Future<String> _getCacheFilePath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return p.join(directory.path, fileName);
  }

  // Method to save data to a file.
  Future<void> saveCache(String key, String data) async {
    final filePath = await _getCacheFilePath(key);
    final file = File(filePath);
    await file.writeAsString(data);
  }

  // Method to read data from a file.
  Future<String?> readCache(String key) async {
    try {
      final filePath = await _getCacheFilePath(key);
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
