import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveJsonFileNative(String jsonString) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/eat_fitness_backup_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(jsonString);
  return file.path;
}

Future<String> saveCsvFileNative(String csvString) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/eat_fitness_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(csvString);
  return file.path;
}

Future<Map<String, dynamic>?> importJsonNative() async {
  // Импорт через file_picker вынесен в основной файл, так как file_picker кроссплатформенный
  return null;
}
