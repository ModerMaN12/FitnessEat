import 'dart:math';
import 'package:hive/hive.dart';

part 'water_entry.g.dart';

String _generateUuid() {
  final rnd = Random();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

@HiveType(typeId: 12)
class WaterEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double amount; // in ml

  @HiveField(2)
  String userId = '';

  @HiveField(3)
  DateTime createdAt = DateTime.now();

  @HiveField(4)
  DateTime updatedAt = DateTime.now();

  @HiveField(5)
  bool isSynced = false;

  @HiveField(6)
  String id;

  WaterEntry({
    required this.date,
    required this.amount,
    String? id,
    this.userId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : id = id ?? _generateUuid(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
