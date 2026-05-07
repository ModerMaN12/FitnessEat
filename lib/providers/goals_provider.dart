import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/goals.dart';

class GoalsProvider extends ChangeNotifier {
  late Box<Goals> _goalsBox;
  Goals? _goals;

  Goals? get goals => _goals;

  double get calories => _goals?.calories ?? 2000;
  double get proteins => _goals?.proteins ?? 150;
  double get fats => _goals?.fats ?? 70;
  double get carbs => _goals?.carbs ?? 250;
  double get water => _goals?.water ?? 2000;

  Future<void> init() async {
    _goalsBox = await Hive.openBox<Goals>('goals');
    if (_goalsBox.isEmpty) {
      final defaultGoals = Goals();
      await _goalsBox.put('main', defaultGoals);
    }
    _goals = _goalsBox.get('main');
    notifyListeners();
  }

  Future<void> reload() async {
    _goals = _goalsBox.get('main');
    notifyListeners();
  }

  Future<void> updateGoals(Goals newGoals) async {
    await _goalsBox.put('main', newGoals);
    _goals = newGoals;
    notifyListeners();
  }

  double getProgress(double current, double goal) {
    if (goal == 0) return 0;
    return (current / goal).clamp(0.0, 1.0);
  }
}
