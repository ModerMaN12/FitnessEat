import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../models/food_item.dart';

class MealProvider extends ChangeNotifier {
  late Box<Meal> _mealBox;
  List<Meal> _meals = [];

  List<Meal> get meals => _meals;

  Future<void> init() async {
    _mealBox = await Hive.openBox<Meal>('meals');
    _loadMeals();
  }

  void _loadMeals() {
    _meals = _mealBox.values.toList();
    _meals.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addMeal(Meal meal) async {
    await _mealBox.put(meal.id, meal);
    _loadMeals();
  }

  Future<void> deleteMeal(String id) async {
    await _mealBox.delete(id);
    _loadMeals();
  }

  Meal? getMealById(String id) {
    return _mealBox.get(id);
  }

  List<Meal> getMealsForDate(DateTime date) {
    return _meals.where((meal) {
      return meal.date.year == date.year &&
          meal.date.month == date.month &&
          meal.date.day == date.day;
    }).toList();
  }

  List<Meal> getMealsForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    return _meals.where((meal) {
      return meal.date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          meal.date.isBefore(endOfWeek.add(Duration(days: 1)));
    }).toList();
  }

  List<Meal> getMealsForMonth(DateTime date) {
    return _meals.where((meal) {
      return meal.date.year == date.year && meal.date.month == date.month;
    }).toList();
  }

  Map<String, double> getTotalsForDate(DateTime date) {
    final dayMeals = getMealsForDate(date);
    double calories = 0, proteins = 0, fats = 0, carbs = 0;

    for (var meal in dayMeals) {
      calories += meal.totalCalories;
      proteins += meal.totalProteins;
      fats += meal.totalFats;
      carbs += meal.totalCarbs;
    }

    return {
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
    };
  }

  Meal? get lastMeal => _meals.isNotEmpty ? _meals.first : null;

  List<Meal> filterMeals({
    DateTime? startDate,
    DateTime? endDate,
    double? minCalories,
    double? maxCalories,
    double? minProteins,
    double? maxProteins,
    double? minFats,
    double? maxFats,
    double? minCarbs,
    double? maxCarbs,
    String? sortBy,
    bool ascending = false,
  }) {
    List<Meal> filtered = List.from(_meals);

    if (startDate != null) {
      filtered = filtered.where((m) => m.date.isAfter(startDate.subtract(Duration(days: 1)))).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((m) => m.date.isBefore(endDate.add(Duration(days: 1)))).toList();
    }
    if (minCalories != null) {
      filtered = filtered.where((m) => m.totalCalories >= minCalories).toList();
    }
    if (maxCalories != null) {
      filtered = filtered.where((m) => m.totalCalories <= maxCalories).toList();
    }
    if (minProteins != null) {
      filtered = filtered.where((m) => m.totalProteins >= minProteins).toList();
    }
    if (maxProteins != null) {
      filtered = filtered.where((m) => m.totalProteins <= maxProteins).toList();
    }
    if (minFats != null) {
      filtered = filtered.where((m) => m.totalFats >= minFats).toList();
    }
    if (maxFats != null) {
      filtered = filtered.where((m) => m.totalFats <= maxFats).toList();
    }
    if (minCarbs != null) {
      filtered = filtered.where((m) => m.totalCarbs >= minCarbs).toList();
    }
    if (maxCarbs != null) {
      filtered = filtered.where((m) => m.totalCarbs <= maxCarbs).toList();
    }

    if (sortBy != null) {
      filtered.sort((a, b) {
        int result = 0;
        switch (sortBy) {
          case 'date':
            result = a.date.compareTo(b.date);
            break;
          case 'calories':
            result = a.totalCalories.compareTo(b.totalCalories);
            break;
          case 'proteins':
            result = a.totalProteins.compareTo(b.totalProteins);
            break;
          case 'fats':
            result = a.totalFats.compareTo(b.totalFats);
            break;
          case 'carbs':
            result = a.totalCarbs.compareTo(b.totalCarbs);
            break;
        }
        return ascending ? result : -result;
      });
    }

    return filtered;
  }
}
