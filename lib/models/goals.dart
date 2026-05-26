import 'package:hive/hive.dart';

part 'goals.g.dart';

@HiveType(typeId: 4)
class Goals extends HiveObject {
  @HiveField(0)
  double calories;

  @HiveField(1)
  double proteins;

  @HiveField(2)
  double fats;

  @HiveField(3)
  double carbs;

  @HiveField(4)
  double water; // in ml

  @HiveField(5)
  String userId = '';

  @HiveField(6)
  DateTime createdAt = DateTime.now();

  @HiveField(7)
  DateTime updatedAt = DateTime.now();

  @HiveField(8)
  bool isSynced = false;

  Goals({
    this.calories = 2000,
    this.proteins = 150,
    this.fats = 70,
    this.carbs = 250,
    this.water = 2000,
    this.userId = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
