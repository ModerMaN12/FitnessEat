import 'package:hive/hive.dart';

part 'food_item.g.dart';

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? imagePath;

  @HiveField(3)
  double calories; // per 100g or whole item

  @HiveField(4)
  double proteins;

  @HiveField(5)
  double fats;

  @HiveField(6)
  double carbs;

  @HiveField(7)
  bool isPer100g; // true if values are per 100g, false if for whole item

  @HiveField(8)
  bool isComposite; // true if it's a recipe/composite dish

  @HiveField(9)
  List<Ingredient>? ingredients; // for composite dishes

  FoodItem({
    required this.id,
    required this.name,
    this.imagePath,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
    this.isPer100g = true,
    this.isComposite = false,
    this.ingredients,
  });

  double getCaloriesForAmount(double grams) {
    if (isPer100g) {
      return (calories / 100) * grams;
    }
    return calories;
  }

  double getProteinsForAmount(double grams) {
    if (isPer100g) {
      return (proteins / 100) * grams;
    }
    return proteins;
  }

  double getFatsForAmount(double grams) {
    if (isPer100g) {
      return (fats / 100) * grams;
    }
    return fats;
  }

  double getCarbsForAmount(double grams) {
    if (isPer100g) {
      return (carbs / 100) * grams;
    }
    return carbs;
  }
}

@HiveType(typeId: 1)
class Ingredient extends HiveObject {
  @HiveField(0)
  String foodItemId;

  @HiveField(1)
  double grams;

  Ingredient({
    required this.foodItemId,
    required this.grams,
  });
}
