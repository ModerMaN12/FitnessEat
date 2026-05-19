import 'package:hive/hive.dart';

part 'water_entry.g.dart';

@HiveType(typeId: 12)
class WaterEntry {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double amount; // in ml

  WaterEntry({
    required this.date,
    required this.amount,
  });
}
