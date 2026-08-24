import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/water_entry.dart';
import '../services/deletion_tracker.dart';

class WaterProvider extends ChangeNotifier {
  late Box<WaterEntry> _waterBox;
  final DeletionTracker _deletionTracker;
  Map<String, double> _dailyWater = {};

  WaterProvider({DeletionTracker? deletionTracker})
      : _deletionTracker = deletionTracker ?? DeletionTracker();

  double getWaterForDate(DateTime date) {
    final key = _dateKey(date);
    return _dailyWater[key] ?? 0;
  }

  Future<void> init() async {
    _waterBox = await Hive.openBox<WaterEntry>('water');
    _loadWater();
  }

  Future<void> reload() async {
    _loadWater();
  }

  void _loadWater() {
    _dailyWater = {};
    for (var entry in _waterBox.values) {
      final key = _dateKey(entry.date);
      _dailyWater[key] = (_dailyWater[key] ?? 0) + entry.amount;
    }
    notifyListeners();
  }

  Future<void> addWater(DateTime date, double amount) async {
    final key = _dateKey(date);
    _dailyWater[key] = (_dailyWater[key] ?? 0) + amount;
    notifyListeners();

    final entry = WaterEntry(date: date, amount: amount);
    await _waterBox.put(entry.id, entry);
  }

  Future<void> removeWater(DateTime date, double amount) async {
    final key = _dateKey(date);
    _dailyWater[key] = (_dailyWater[key] ?? 0) - amount;
    if (_dailyWater[key]! < 0) _dailyWater[key] = 0;
    notifyListeners();

    final entries = _waterBox.values
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (entries.isNotEmpty) {
      final entry = entries.first;
      entry.isSynced = false;
      entry.updatedAt = DateTime.now();
      final newAmount = entry.amount - amount;
      if (newAmount <= 0) {
        await _waterBox.delete(entry.id);
        await _deletionTracker.track(entry.id, 'water_entries');
      } else {
        entry.amount = newAmount;
        await _waterBox.put(entry.id, entry);
      }
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
