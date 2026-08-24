import 'package:hive_flutter/hive_flutter.dart';

class DeletionTracker {
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>('pending_deletes');
  }

  Future<void> track(String id, String table) async {
    await _box.put(id, table);
  }

  Future<void> untrack(String id) async {
    await _box.delete(id);
  }

  bool isPending(String id) => _box.containsKey(id);

  String? tableOf(String id) => _box.get(id);

  List<String> idsByTable(String table) => _box.keys
      .where((id) => _box.get(id) == table)
      .map((id) => id as String)
      .toList();
}