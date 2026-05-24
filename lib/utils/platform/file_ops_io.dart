import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class PlatformFileOps {
  static Future<Uint8List?> readFileBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  static Future<String> saveJsonFile(String jsonString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/eat_fitness_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonString, encoding: utf8);
    return file.path;
  }

  static Future<String> saveCsvFile(String csvString) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/eat_fitness_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final bytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csvString);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<String?> saveImageFromBase64(
      String base64String, String id) async {
    try {
      final bytes = base64Decode(base64String);
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final file = File('${imageDir.path}/$id.jpg');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> readImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }
}
