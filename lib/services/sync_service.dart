import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/goals.dart';
import '../models/meal_template.dart';
import '../models/water_entry.dart';
import 'deletion_tracker.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService extends ChangeNotifier {
  final SupabaseClient _supabase;
  final Connectivity _connectivity;
  final DeletionTracker _deletionTracker;

  SyncStatus _status = SyncStatus.idle;
  String? _error;
  DateTime? _lastSyncAt;
  bool _isOnline = true;
  String _currentStage = '';
  Timer? _connectivityTimer;

  int _pushedCount = 0;
  int _pulledCount = 0;

  SyncService(this._supabase, this._connectivity, {DeletionTracker? deletionTracker})
      : _deletionTracker = deletionTracker ?? DeletionTracker() {
    _init();
  }

  SyncStatus get status => _status;
  String? get error => _error;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get isOnline => _isOnline;
  String get currentStage => _currentStage;
  int get pushedCount => _pushedCount;
  int get pulledCount => _pulledCount;

  void _init() {
    _loadLastSync();
    _checkConnectivity();

    _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (_isOnline && wasOffline) {
        fullSync();
      }
      notifyListeners();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    } catch (_) {
      _isOnline = true;
    }

    if (kIsWeb) {
      _connectivityTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _checkWebConnectivity(),
      );
    }
  }

  Future<void> _checkWebConnectivity() async {
    try {
      await Supabase.instance.client.from('foods')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 5));
      if (!_isOnline) {
        _isOnline = true;
        notifyListeners();
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('last_sync_at');
    if (ts != null) {
      _lastSyncAt = DateTime.tryParse(ts);
    }
  }

  Future<void> _saveLastSync(DateTime dt) async {
    _lastSyncAt = dt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_at', dt.toIso8601String());
  }

  Future<void> fullSync() async {
    if (_status == SyncStatus.syncing) return;

    if (!_isOnline) {
      _error = 'Нет подключения к интернету';
      _status = SyncStatus.error;
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    _error = null;
    _pushedCount = 0;
    _pulledCount = 0;
    _currentStage = 'Проверка подключения...';
    notifyListeners();

    final hasSession = _supabase.auth.currentUser != null;
    if (!hasSession) {
      _error = 'Необходимо авторизоваться';
      _status = SyncStatus.error;
      notifyListeners();
      return;
    }

    String? stageError;

    stageError = await _runStage('Синхронизация удалений...', _flushDeletes);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Отправка продуктов...', _pushFoods);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Отправка приёмов пищи...', _pushMeals);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Отправка целей...', _pushGoals);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Отправка шаблонов...', _pushTemplates);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Отправка записей воды...', _pushWaterEntries);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Загрузка продуктов с сервера...', _pullFoods);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Загрузка приёмов пищи...', _pullMeals);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Загрузка целей...', _pullGoals);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Загрузка шаблонов...', _pullTemplates);
    if (stageError != null) { _setError(stageError); return; }

    stageError = await _runStage('Загрузка записей воды...', _pullWaterEntries);
    if (stageError != null) { _setError(stageError); return; }

    await _saveLastSync(DateTime.now());
    _currentStage = 'Готово';
    _status = SyncStatus.success;
    notifyListeners();
  }

  Future<String?> _runStage(String label, Future<void> Function() stage) async {
    _currentStage = label;
    notifyListeners();
    try {
      await stage();
      return null;
    } on TimeoutException {
      return '$label — таймаут. Сервер не отвечает.';
    } catch (e) {
      return '$label — $e';
    }
  }

  void _setError(String msg) {
    _error = msg;
    _status = SyncStatus.error;
    notifyListeners();
  }

  Future<void> _flushDeletes() async {
    final userId = _supabase.auth.currentUser!.id;
    const tables = ['foods', 'meals', 'templates', 'water_entries'];

    for (final table in tables) {
      final ids = _deletionTracker.idsByTable(table);
      if (ids.isEmpty) continue;

      await _supabase
          .from(table)
          .delete()
          .eq('user_id', userId)
          .inFilter('id', ids)
          .timeout(const Duration(seconds: 10));

      for (final id in ids) {
        await _deletionTracker.untrack(id);
      }
    }
  }

  Future<void> _pushFoods() async {
    final box = Hive.box<FoodItem>('foods');
    final unsynced = box.values.where((f) => !f.isSynced).toList();
    if (unsynced.isEmpty) return;

    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();

    final foodsPayload = unsynced.map((food) {
      food.userId = userId;
      food.updatedAt = now;
      return {
        'id': food.id,
        'user_id': userId,
        'name': food.name,
        'image_url': food.imagePath,
        'calories': food.calories,
        'proteins': food.proteins,
        'fats': food.fats,
        'carbs': food.carbs,
        'is_per_100g': food.isPer100g,
        'is_composite': food.isComposite,
        'updated_at': now.toIso8601String(),
      };
    }).toList();

    await _supabase.from('foods')
        .upsert(foodsPayload)
        .timeout(const Duration(seconds: 15));

    final foodIds = unsynced.map((f) => f.id).toList();
    await _supabase.from('food_ingredients')
        .delete()
        .inFilter('food_id', foodIds)
        .timeout(const Duration(seconds: 10));

    final allIngredients = <Map<String, dynamic>>[];
    for (final food in unsynced) {
      if (food.ingredients != null) {
        for (final ing in food.ingredients!) {
          allIngredients.add({
            'food_id': food.id,
            'ingredient_food_id': ing.foodItemId,
            'grams': ing.grams,
          });
        }
      }
    }
    if (allIngredients.isNotEmpty) {
      await _supabase.from('food_ingredients')
          .insert(allIngredients)
          .timeout(const Duration(seconds: 10));
    }

    for (final food in unsynced) {
      food.isSynced = true;
      await food.save();
    }
    _pushedCount += unsynced.length;
  }

  Future<void> _pushMeals() async {
    final box = Hive.box<Meal>('meals');
    final unsynced = box.values.where((m) => !m.isSynced).toList();
    if (unsynced.isEmpty) return;

    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();

    final mealsPayload = unsynced.map((meal) {
      meal.userId = userId;
      meal.updatedAt = now;
      return {
        'id': meal.id,
        'user_id': userId,
        'date': meal.date.toIso8601String(),
        'type': meal.type,
        'image_url': meal.imagePath,
        'total_calories': meal.totalCalories,
        'total_proteins': meal.totalProteins,
        'total_fats': meal.totalFats,
        'total_carbs': meal.totalCarbs,
        'updated_at': now.toIso8601String(),
      };
    }).toList();

    await _supabase.from('meals')
        .upsert(mealsPayload)
        .timeout(const Duration(seconds: 15));

    final mealIds = unsynced.map((m) => m.id).toList();
    await _supabase.from('meal_items')
        .delete()
        .inFilter('meal_id', mealIds)
        .timeout(const Duration(seconds: 10));

    final allItems = <Map<String, dynamic>>[];
    for (final meal in unsynced) {
      for (final item in meal.items) {
        allItems.add({
          'meal_id': meal.id,
          'food_item_id': item.foodItemId,
          'grams': item.grams,
          'food_name': item.foodName,
        });
      }
    }
    if (allItems.isNotEmpty) {
      await _supabase.from('meal_items')
          .insert(allItems)
          .timeout(const Duration(seconds: 10));
    }

    for (final meal in unsynced) {
      meal.isSynced = true;
      await meal.save();
    }
    _pushedCount += unsynced.length;
  }

  Future<void> _pushGoals() async {
    final box = Hive.box<Goals>('goals');
    final goal = box.get('main');
    if (goal == null || goal.isSynced) return;

    goal.userId = _supabase.auth.currentUser!.id;
    goal.updatedAt = DateTime.now();

    await _supabase.from('goals')
        .upsert({
          'user_id': goal.userId,
          'calories': goal.calories,
          'proteins': goal.proteins,
          'fats': goal.fats,
          'carbs': goal.carbs,
          'water': goal.water,
          'updated_at': goal.updatedAt.toIso8601String(),
        })
        .timeout(const Duration(seconds: 10));

    goal.isSynced = true;
    await goal.save();
    _pushedCount++;
  }

  Future<void> _pushTemplates() async {
    final box = Hive.box<MealTemplate>('templates');
    final unsynced = box.values.where((t) => !t.isSynced).toList();
    if (unsynced.isEmpty) return;

    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();

    final templatesPayload = unsynced.map((t) {
      t.userId = userId;
      t.updatedAt = now;
      return {
        'id': t.id,
        'user_id': userId,
        'name': t.name,
        'type': t.type,
        'updated_at': now.toIso8601String(),
      };
    }).toList();

    await _supabase.from('templates')
        .upsert(templatesPayload)
        .timeout(const Duration(seconds: 15));

    final templateIds = unsynced.map((t) => t.id).toList();
    await _supabase.from('template_items')
        .delete()
        .inFilter('template_id', templateIds)
        .timeout(const Duration(seconds: 10));

    final allItems = <Map<String, dynamic>>[];
    for (final template in unsynced) {
      for (final item in template.items) {
        allItems.add({
          'template_id': template.id,
          'food_item_id': item.foodItemId,
          'grams': item.grams,
          'food_name': item.foodName,
        });
      }
    }
    if (allItems.isNotEmpty) {
      await _supabase.from('template_items')
          .insert(allItems)
          .timeout(const Duration(seconds: 10));
    }

    for (final template in unsynced) {
      template.isSynced = true;
      await template.save();
    }
    _pushedCount += unsynced.length;
  }

  Future<void> _pushWaterEntries() async {
    final box = Hive.box<WaterEntry>('water');
    final unsynced = box.values.where((w) => !w.isSynced).toList();
    if (unsynced.isEmpty) return;

    final userId = _supabase.auth.currentUser!.id;
    final now = DateTime.now();

    for (final entry in unsynced) {
      entry.userId = userId;
      entry.updatedAt = now;
    }

    await _supabase.from('water_entries')
        .upsert(unsynced.map((e) => {
          'id': e.id,
          'user_id': userId,
          'date': '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
          'amount': e.amount,
          'updated_at': now.toIso8601String(),
        }).toList())
        .timeout(const Duration(seconds: 15));

    for (final entry in unsynced) {
      entry.isSynced = true;
      await entry.save();
    }
    _pushedCount += unsynced.length;
  }

  Future<void> _pullFoods() async {
    final userId = _supabase.auth.currentUser!.id;
    final cutoff = _lastSyncAt?.toIso8601String() ?? '1970-01-01T00:00:00';

    final response = await _supabase
        .from('foods')
        .select('*')
        .eq('user_id', userId)
        .gte('updated_at', cutoff)
        .timeout(const Duration(seconds: 15));

    final box = Hive.box<FoodItem>('foods');
    for (final row in response) {
      final id = row['id'] as String;
      if (_deletionTracker.isPending(id)) continue;
      final serverUpdated = DateTime.parse(row['updated_at'] as String);
      final local = box.get(id);
      if (local == null || local.updatedAt.isBefore(serverUpdated)) {
        List<Ingredient>? ingredients;
        try {
          final ingResp = await _supabase
              .from('food_ingredients')
              .select('ingredient_food_id, grams')
              .eq('food_id', row['id'] as String)
              .timeout(const Duration(seconds: 10));
          if (ingResp.isNotEmpty) {
            ingredients = ingResp.map((i) => Ingredient(
              foodItemId: i['ingredient_food_id'] as String,
              grams: (i['grams'] as num).toDouble(),
            )).toList();
          }
        } catch (_) {}

await box.put(row['id'] as String, FoodItem(
                  id: id,
          name: row['name'] as String,
          imagePath: row['image_url'] as String?,
          calories: (row['calories'] as num).toDouble(),
          proteins: (row['proteins'] as num).toDouble(),
          fats: (row['fats'] as num).toDouble(),
          carbs: (row['carbs'] as num).toDouble(),
          isPer100g: row['is_per_100g'] as bool? ?? true,
          isComposite: row['is_composite'] as bool? ?? false,
          ingredients: ingredients,
          userId: row['user_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: serverUpdated,
          isSynced: true,
        ));
        _pulledCount++;
      }
    }
  }

  Future<void> _pullMeals() async {
    final userId = _supabase.auth.currentUser!.id;
    final cutoff = _lastSyncAt?.toIso8601String() ?? '1970-01-01T00:00:00';

    final response = await _supabase
        .from('meals')
        .select('*')
        .eq('user_id', userId)
        .gte('updated_at', cutoff)
        .timeout(const Duration(seconds: 15));

    final box = Hive.box<Meal>('meals');
    final foodBox = Hive.box<FoodItem>('foods');

    for (final row in response) {
      final id = row['id'] as String;
      if (_deletionTracker.isPending(id)) continue;
      final serverUpdated = DateTime.parse(row['updated_at'] as String);
      final local = box.get(id);
      if (local == null || local.updatedAt.isBefore(serverUpdated)) {
        List<MealItem> items = [];
        try {
          final itemsResp = await _supabase
              .from('meal_items')
              .select('food_item_id, grams, food_name')
              .eq('meal_id', row['id'] as String)
              .timeout(const Duration(seconds: 10));

          items = itemsResp.map((i) {
            final item = MealItem(
              foodItemId: i['food_item_id'] as String,
              grams: (i['grams'] as num).toDouble(),
              foodName: i['food_name'] as String?,
            );
            final food = foodBox.get(item.foodItemId);
            if (food != null) {
              item.calories = food.getCaloriesForAmount(item.grams);
              item.proteins = food.getProteinsForAmount(item.grams);
              item.fats = food.getFatsForAmount(item.grams);
              item.carbs = food.getCarbsForAmount(item.grams);
            }
            return item;
          }).toList();
        } catch (_) {}

        await box.put(id, Meal(
          id: id,
          date: DateTime.parse(row['date'] as String),
          type: row['type'] as String,
          items: items,
          imagePath: row['image_url'] as String?,
          totalCalories: (row['total_calories'] as num).toDouble(),
          totalProteins: (row['total_proteins'] as num).toDouble(),
          totalFats: (row['total_fats'] as num).toDouble(),
          totalCarbs: (row['total_carbs'] as num).toDouble(),
          userId: row['user_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: serverUpdated,
          isSynced: true,
        ));
        _pulledCount++;
      }
    }
  }

  Future<void> _pullGoals() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('goals')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (response == null) return;

    final box = Hive.box<Goals>('goals');
    final local = box.get('main');
    final serverUpdated = DateTime.parse(response['updated_at'] as String);

    if (local == null || local.updatedAt.isBefore(serverUpdated)) {
      await box.put('main', Goals(
        calories: (response['calories'] as num?)?.toDouble() ?? 2000,
        proteins: (response['proteins'] as num?)?.toDouble() ?? 150,
        fats: (response['fats'] as num?)?.toDouble() ?? 70,
        carbs: (response['carbs'] as num?)?.toDouble() ?? 250,
        water: (response['water'] as num?)?.toDouble() ?? 2000,
        userId: response['user_id'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: serverUpdated,
        isSynced: true,
      ));
      _pulledCount++;
    }
  }

  Future<void> _pullTemplates() async {
    final userId = _supabase.auth.currentUser!.id;
    final cutoff = _lastSyncAt?.toIso8601String() ?? '1970-01-01T00:00:00';

    final response = await _supabase
        .from('templates')
        .select('*')
        .eq('user_id', userId)
        .gte('updated_at', cutoff)
        .timeout(const Duration(seconds: 15));

    final box = Hive.box<MealTemplate>('templates');
    for (final row in response) {
      final id = row['id'] as String;
      if (_deletionTracker.isPending(id)) continue;
      final serverUpdated = DateTime.parse(row['updated_at'] as String);
      final local = box.get(id);
      if (local == null || local.updatedAt.isBefore(serverUpdated)) {
        List<TemplateItem> items = [];
        try {
          final itemsResp = await _supabase
              .from('template_items')
              .select('food_item_id, grams, food_name')
              .eq('template_id', row['id'] as String)
              .timeout(const Duration(seconds: 10));

          items = itemsResp.map((i) => TemplateItem(
            foodItemId: i['food_item_id'] as String,
            grams: (i['grams'] as num).toDouble(),
            foodName: i['food_name'] as String?,
          )).toList();
        } catch (_) {}

        await box.put(id, MealTemplate(
          id: id,
          name: row['name'] as String,
          type: row['type'] as String,
          items: items,
          userId: row['user_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: serverUpdated,
          isSynced: true,
        ));
        _pulledCount++;
      }
    }
  }

  Future<void> _pullWaterEntries() async {
    final userId = _supabase.auth.currentUser!.id;
    final cutoff = _lastSyncAt?.toIso8601String() ?? '1970-01-01T00:00:00';

    final response = await _supabase
        .from('water_entries')
        .select('*')
        .eq('user_id', userId)
        .gte('updated_at', cutoff)
        .timeout(const Duration(seconds: 15));

    final box = Hive.box<WaterEntry>('water');
    for (final row in response) {
      final serverUpdated = DateTime.parse(row['updated_at'] as String);
      final id = row['id'] as String;
      if (_deletionTracker.isPending(id)) continue;
      final local = box.get(id);
      if (local == null || local.updatedAt.isBefore(serverUpdated)) {
        await box.put(id, WaterEntry(
          date: DateTime.parse(row['date'] as String),
          amount: (row['amount'] as num).toDouble(),
          id: id,
          userId: row['user_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: serverUpdated,
          isSynced: true,
        ));
        _pulledCount++;
      }
    }
  }
}
