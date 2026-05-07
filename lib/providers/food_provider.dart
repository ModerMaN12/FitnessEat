import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_item.dart';

class FoodProvider extends ChangeNotifier {
  late Box<FoodItem> _foodBox;
  List<FoodItem> _foods = [];

  List<FoodItem> get foods => _foods;

  List<FoodItem> get simpleFoods =>
      _foods.where((f) => !f.isComposite).toList();
  List<FoodItem> get compositeFoods =>
      _foods.where((f) => f.isComposite).toList();

  Future<void> init() async {
    _foodBox = await Hive.openBox<FoodItem>('foods');
    _loadFoods();
  }

  Future<void> reload() async {
    _loadFoods();
  }

  void _loadFoods() {
    _foods = _foodBox.values.toList();
    notifyListeners();
  }

  Future<void> addFood(FoodItem item) async {
    await _foodBox.put(item.id, item);
    _loadFoods();
  }

  Future<void> updateFood(FoodItem item) async {
    await item.save();
    _loadFoods();
  }

  Future<void> deleteFood(String id) async {
    await _foodBox.delete(id);
    _loadFoods();
  }

  FoodItem? getFoodById(String id) {
    return _foodBox.get(id);
  }

  List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return _foods;
    return _foods
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<FoodItem> filterByKbju({
    double? minCalories,
    double? maxCalories,
    double? minProteins,
    double? maxProteins,
    double? minFats,
    double? maxFats,
    double? minCarbs,
    double? maxCarbs,
  }) {
    return _foods.where((food) {
      if (minCalories != null && food.calories < minCalories) return false;
      if (maxCalories != null && food.calories > maxCalories) return false;
      if (minProteins != null && food.proteins < minProteins) return false;
      if (maxProteins != null && food.proteins > maxProteins) return false;
      if (minFats != null && food.fats < minFats) return false;
      if (maxFats != null && food.fats > maxFats) return false;
      if (minCarbs != null && food.carbs < minCarbs) return false;
      if (maxCarbs != null && food.carbs > maxCarbs) return false;
      return true;
    }).toList();
  }
}
