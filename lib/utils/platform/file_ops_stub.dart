import 'dart:typed_data';
import 'dart:convert';

class PlatformFileOps {
  static Future<Uint8List?> readFileBytes(String path) async {
    return null;
  }

  static Future<String> saveJsonFile(String jsonString) async {
    return jsonString;
  }

  static Future<String> saveCsvFile(String csvString) async {
    return csvString;
  }

  static Future<String?> saveImageFromBase64(
      String base64String, String id) async {
    return null;
  }

  static Future<bool> fileExists(String path) async {
    return false;
  }

  static Future<Uint8List?> readImageFile(String path) async {
    return null;
  }
}
