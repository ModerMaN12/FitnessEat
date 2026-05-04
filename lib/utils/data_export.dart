import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/goals.dart';

class DataExport {
  // Экспорт всех данных в JSON
  static Future<String> exportToJson() async {
    final foodBox = Hive.box<FoodItem>('foods');
    final mealBox = Hive.box<Meal>('meals');
    final goalsBox = Hive.box<Goals>('goals');

    final data = {
      'foods': foodBox.values.map((item) => _foodItemToMap(item)).toList(),
      'meals': mealBox.values.map((meal) => _mealToMap(meal)).toList(),
      'goals': goalsBox.values.map((g) => _goalsToMap(g)).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    
    if (kIsWeb) {
      return jsonString;
    } else {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/eat_fitness_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      return file.path;
    }
  }

  // Импорт из JSON
  static Future<void> importFromJson(BuildContext context) async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Импорт недоступен в веб-версии')),
        );
        return;
      }
      
      // Для мобильных/десктопов - здесь должен быть код выбора файла
      // Пока просто показываем сообщение
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Импорт: выберите файл в файловом менеджере')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  // Экспорт в CSV
  static Future<String> exportToCsv() async {
    final mealBox = Hive.box<Meal>('meals');
    final meals = mealBox.values.toList();

    List<List<dynamic>> rows = [];
    rows.add(['Дата', 'Тип', 'Калории', 'Белки', 'Жиры', 'Углеводы', 'Продукты']);

    for (var meal in meals) {
      final products = meal.items.map((item) => item.foodName ?? '').join(', ');
      rows.add([
        meal.date.toIso8601String(),
        meal.type,
        meal.totalCalories,
        meal.totalProteins,
        meal.totalFats,
        meal.totalCarbs,
        products,
      ]);
    }

    String csv = _convertToCsv(rows);

    if (kIsWeb) {
      return csv;
    } else {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/eat_fitness_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      return file.path;
    }
  }

  // Простая конвертация в CSV
  static String _convertToCsv(List<List<dynamic>> rows) {
    String result = '';
    for (var row in rows) {
      result += row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',') + '\n';
    }
    return result;
  }

  // Вспомогательные методы для конвертации
  static Map<String, dynamic> _foodItemToMap(FoodItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'imagePath': item.imagePath,
      'calories': item.calories,
      'proteins': item.proteins,
      'fats': item.fats,
      'carbs': item.carbs,
      'isPer100g': item.isPer100g,
      'isComposite': item.isComposite,
    };
  }

  static FoodItem _mapToFoodItem(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      calories: map['calories'],
      proteins: map['proteins'],
      fats: map['fats'],
      carbs: map['carbs'],
      isPer100g: map['isPer100g'] ?? true,
      isComposite: map['isComposite'] ?? false,
    );
  }

  static Map<String, dynamic> _mealToMap(Meal meal) {
    return {
      'id': meal.id,
      'date': meal.date.toIso8601String(),
      'type': meal.type,
      'items': meal.items
          .map((item) => {
                'foodItemId': item.foodItemId,
                'grams': item.grams,
                'foodName': item.foodName,
              })
          .toList(),
      'imagePath': meal.imagePath,
      'totalCalories': meal.totalCalories,
      'totalProteins': meal.totalProteins,
      'totalFats': meal.totalFats,
      'totalCarbs': meal.totalCarbs,
    };
  }

  static Meal _mapToMeal(Map<String, dynamic> map) {
    final meal = Meal(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      items: (map['items'] as List)
          .map((item) => MealItem(
                foodItemId: item['foodItemId'],
                grams: item['grams'],
                foodName: item['foodName'],
              ))
          .toList(),
      imagePath: map['imagePath'],
      totalCalories: map['totalCalories'],
      totalProteins: map['totalProteins'],
      totalFats: map['totalFats'],
      totalCarbs: map['totalCarbs'],
    );
    return meal;
  }

  static Map<String, dynamic> _goalsToMap(Goals goals) {
    return {
      'calories': goals.calories,
      'proteins': goals.proteins,
      'fats': goals.fats,
      'carbs': goals.carbs,
      'water': goals.water,
    };
  }

  static Goals _mapToGoals(Map<String, dynamic> map) {
    return Goals(
      calories: map['calories'] ?? 2000,
      proteins: map['proteins'] ?? 150,
      fats: map['fats'] ?? 70,
      carbs: map['carbs'] ?? 250,
      water: map['water'] ?? 2000,
    );
  }
}
