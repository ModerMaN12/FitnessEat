import 'package:hive/hive.dart';

part 'meal_template.g.dart';

@HiveType(typeId: 10)
class MealTemplate {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // breakfast, lunch, dinner, snack

  @HiveField(3)
  List<TemplateItem> items;

  MealTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.items,
  });
}

@HiveType(typeId: 11)
class TemplateItem {
  @HiveField(0)
  String foodItemId;

  @HiveField(1)
  double grams;

  @HiveField(2)
  String? foodName;

  TemplateItem({
    required this.foodItemId,
    required this.grams,
    this.foodName,
  });
}
