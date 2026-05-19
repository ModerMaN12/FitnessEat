import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/water_entry.dart';

class WaterProvider extends ChangeNotifier {
  late Box<WaterEntry> _waterBox;
  Map<String, double> _dailyWater = {};

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
    final entry = WaterEntry(date: date, amount: amount);
    await _waterBox.add(entry);

    final key = _dateKey(date);
    _dailyWater[key] = (_dailyWater[key] ?? 0) + amount;
    notifyListeners();
  }

  Future<void> removeWater(DateTime date, double amount) async {
    final key = _dateKey(date);
    _dailyWater[key] = (_dailyWater[key] ?? 0) - amount;
    if (_dailyWater[key]! < 0) _dailyWater[key] = 0;

    notifyListeners();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
