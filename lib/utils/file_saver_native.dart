import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<String> saveJsonFile(String jsonString) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/eat_fitness_backup_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(jsonString, encoding: utf8);
  return file.path;
}

Future<String> saveCsvFile(String csvString) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/eat_fitness_export_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(csvString, encoding: utf8);
  return file.path;
}
