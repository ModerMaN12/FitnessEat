import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 2)
class MealItem {
  @HiveField(0)
  String foodItemId;

  @HiveField(1)
  double grams;

  @HiveField(2)
  String? foodName;

  MealItem({
    required this.foodItemId,
    required this.grams,
    this.foodName,
  });

  double calories = 0;
  double proteins = 0;
  double fats = 0;
  double carbs = 0;
}

@HiveType(typeId: 3)
class Meal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String type; // breakfast, lunch, dinner, snack

  @HiveField(3)
  List<MealItem> items;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  double totalCalories;

  @HiveField(6)
  double totalProteins;

  @HiveField(7)
  double totalFats;

  @HiveField(8)
  double totalCarbs;

  Meal({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    this.imagePath,
    this.totalCalories = 0,
    this.totalProteins = 0,
    this.totalFats = 0,
    this.totalCarbs = 0,
  });
}
