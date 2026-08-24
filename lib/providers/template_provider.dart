import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_template.dart';
import '../services/deletion_tracker.dart';

class TemplateProvider extends ChangeNotifier {
  late Box<MealTemplate> _templateBox;
  final DeletionTracker _deletionTracker;
  List<MealTemplate> _templates = [];

  TemplateProvider({DeletionTracker? deletionTracker})
      : _deletionTracker = deletionTracker ?? DeletionTracker();

  List<MealTemplate> get templates => _templates;

  Future<void> init() async {
    _templateBox = await Hive.openBox<MealTemplate>('templates');
    _loadTemplates();
  }

  Future<void> reload() async {
    _loadTemplates();
  }

  void _loadTemplates() {
    _templates = _templateBox.values.toList();
    notifyListeners();
  }

  Future<void> addTemplate(MealTemplate template) async {
    await _templateBox.put(template.id, template);
    _loadTemplates();
  }

  Future<void> updateTemplate(MealTemplate template) async {
    await _templateBox.put(template.id, template);
    _loadTemplates();
  }

  Future<void> deleteTemplate(String id) async {
    await _templateBox.delete(id);
    await _deletionTracker.track(id, 'templates');
    _loadTemplates();
  }

  MealTemplate? getTemplateById(String id) {
    return _templateBox.get(id);
  }
}
