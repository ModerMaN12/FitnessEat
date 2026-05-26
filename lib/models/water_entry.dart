import 'package:hive/hive.dart';

part 'water_entry.g.dart';

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

  WaterEntry({
    required this.date,
    required this.amount,
    this.userId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
