import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;

  SyncProvider(this._syncService) {
    _syncService.addListener(_onSyncChanged);
  }

  SyncStatus get status => _syncService.status;
  String? get error => _syncService.error;
  DateTime? get lastSyncAt => _syncService.lastSyncAt;
  bool get isOnline => _syncService.isOnline;
  bool get isSyncing => _syncService.status == SyncStatus.syncing;
  String get currentStage => _syncService.currentStage;
  int get pushedCount => _syncService.pushedCount;
  int get pulledCount => _syncService.pulledCount;

  Future<void> sync() => _syncService.fullSync();

  void _onSyncChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncChanged);
    super.dispose();
  }
}
