import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/goals.dart';
import '../models/meal_template.dart';
import 'platform_file_ops.dart';
import 'platform_share.dart';

class DataExport {
  static Future<String> exportToJson() async {
    final foodBox = Hive.box<FoodItem>('foods');
    final mealBox = Hive.box<Meal>('meals');
    final goalsBox = Hive.box<Goals>('goals');
    final templateBox = Hive.box<MealTemplate>('templates');

    final foods = await Future.wait<Map<String, dynamic>>(
      foodBox.values.map((item) => _foodItemToMap(item)).toList(),
    );
    final meals = await Future.wait<Map<String, dynamic>>(
      mealBox.values.map((meal) => _mealToMap(meal)).toList(),
    );

    final data = {
      'foods': foods,
      'meals': meals,
      'goals': goalsBox.values.map((g) => _goalsToMap(g)).toList(),
      'templates': templateBox.values.map((t) => _templateToMap(t)).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  static Future<String> saveJsonFile(String jsonString) async {
    return await PlatformFileOps.saveJsonFile(jsonString);
  }

  static Future<Map<String, dynamic>?> importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) {
        return null;
      }

      final file = result.files.single;

      // 优先使用bytes（Web和移动端）
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        final jsonString = utf8.decode(file.bytes!);
        final data = jsonDecode(jsonString);
        if (data is Map<String, dynamic>) return data;
      }

      // 桌面端和移动端使用path读取
      if (file.path != null && !kIsWeb) {
        try {
          return await _readFileDesktop(file.path!);
        } catch (e) {
          throw Exception('读取文件失败: $e');
        }
      }

      // 移动端如果bytes为空但path存在，尝试读取
      if (file.path != null && file.bytes == null) {
        try {
          final bytes = await PlatformFileOps.readFileBytes(file.path!);
          if (bytes != null) {
            final jsonString = utf8.decode(bytes);
            final data = jsonDecode(jsonString);
            if (data is Map<String, dynamic>) return data;
          }
        } catch (e) {
          throw Exception('移动端读取文件失败: $e');
        }
      }

      throw Exception('无法读取文件，请选择其他文件');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> applyImportedData(Map<String, dynamic> data) async {
    final foodBox = Hive.box<FoodItem>('foods');
    final mealBox = Hive.box<Meal>('meals');
    final goalsBox = Hive.box<Goals>('goals');
    final templateBox = Hive.box<MealTemplate>('templates');

    await foodBox.clear();
    await mealBox.clear();
    await goalsBox.clear();
    await templateBox.clear();

    if (data['foods'] != null) {
      for (var item in data['foods']) {
        final food = await _mapToFoodItem(item);
        if (food != null) await foodBox.put(food.id, food);
      }
    }

    if (data['meals'] != null) {
      for (var item in data['meals']) {
        final meal = await _mapToMeal(item);
        if (meal != null) await mealBox.put(meal.id, meal);
      }
    }

    if (data['goals'] != null && (data['goals'] as List).isNotEmpty) {
      final goals = _mapToGoals(data['goals'][0]);
      await goalsBox.put('daily', goals);
    }

    if (data['templates'] != null) {
      for (var item in data['templates']) {
        final template = _mapToTemplate(item);
        await templateBox.put(template.id, template);
      }
    }

    // Force flush to ensure all data is written to disk
    await foodBox.flush();
    await mealBox.flush();
    await goalsBox.flush();
    await templateBox.flush();
  }

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

    return _convertToCsv(rows);
  }

  static Future<String> saveCsvFile(String csvString) async {
    return await PlatformFileOps.saveCsvFile(csvString);
  }

  static Future<void> shareFile(String filePath) async {
    await PlatformShare.shareFile(filePath, 'Eat Fitness Export');
  }

  static String _convertToCsv(List<List<dynamic>> rows) {
    String result = '';
    for (var row in rows) {
      result += row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',') + '\n';
    }
    return result;
  }

  static void showDataDialog(BuildContext context, String content, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, dynamic>> _foodItemToMap(FoodItem item) async {
    String? imageData;
    if (item.imagePath != null) {
      try {
        final bytes = await PlatformFileOps.readImageFile(item.imagePath!);
        if (bytes != null) {
          imageData = base64Encode(bytes);
        }
      } catch (_) {}
    }

    return {
      'id': item.id,
      'name': item.name,
      'imagePath': item.imagePath,
      'imageData': imageData,
      'calories': item.calories,
      'proteins': item.proteins,
      'fats': item.fats,
      'carbs': item.carbs,
      'isPer100g': item.isPer100g,
      'isComposite': item.isComposite,
    };
  }

  static Future<FoodItem?> _mapToFoodItem(Map<String, dynamic> map) async {
    try {
      String? imagePath = map['imagePath'];
      if (map['imageData'] != null && map['imageData'].toString().isNotEmpty) {
        imagePath = await _saveImageFromBase64(
          map['imageData'].toString(),
          map['id'],
        );
      }

      return FoodItem(
        id: map['id'],
        name: map['name'],
        imagePath: imagePath,
        calories: map['calories'],
        proteins: map['proteins'],
        fats: map['fats'],
        carbs: map['carbs'],
        isPer100g: map['isPer100g'] ?? true,
        isComposite: map['isComposite'] ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _saveImageFromBase64(
      String base64String, String id) async {
    return await PlatformFileOps.saveImageFromBase64(base64String, id);
  }

  static Future<Map<String, dynamic>> _mealToMap(Meal meal) async {
    String? imageData;
    if (meal.imagePath != null) {
      try {
        final bytes = await PlatformFileOps.readImageFile(meal.imagePath!);
        if (bytes != null) {
          imageData = base64Encode(bytes);
        }
      } catch (_) {}
    }

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
      'imageData': imageData,
      'totalCalories': meal.totalCalories,
      'totalProteins': meal.totalProteins,
      'totalFats': meal.totalFats,
      'totalCarbs': meal.totalCarbs,
    };
  }

  static Future<Meal?> _mapToMeal(Map<String, dynamic> map) async {
    try {
      String? imagePath = map['imagePath'];
      if (map['imageData'] != null && map['imageData'].toString().isNotEmpty) {
        imagePath = await _saveImageFromBase64(
          map['imageData'].toString(),
          map['id'],
        );
      }

      return Meal(
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
        imagePath: imagePath,
        totalCalories: map['totalCalories'],
        totalProteins: map['totalProteins'],
        totalFats: map['totalFats'],
        totalCarbs: map['totalCarbs'],
      );
    } catch (e) {
      return null;
    }
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

  static Map<String, dynamic> _templateToMap(MealTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'type': template.type,
      'items': template.items
          .map((item) => {
                'foodItemId': item.foodItemId,
                'grams': item.grams,
                'foodName': item.foodName,
              })
          .toList(),
    };
  }

  static MealTemplate _mapToTemplate(Map<String, dynamic> map) {
    return MealTemplate(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      items: (map['items'] as List)
          .map((item) => TemplateItem(
                foodItemId: item['foodItemId'],
                grams: item['grams'].toDouble(),
                foodName: item['foodName'],
              ))
          .toList(),
    );
  }

  static Future<Map<String, dynamic>?> _readFileDesktop(String path) async {
    try {
      final bytes = await PlatformFileOps.readFileBytes(path);
      if (bytes == null) return null;
      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
