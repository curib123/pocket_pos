import 'dart:io';

import 'package:flutter/foundation.dart';
import '../core/data/offline_database.dart';
import '../core/data/product_store.dart';

/// Coordinates local backup/restore and exposes sync readiness to the UI.
class OfflineDataProvider extends ChangeNotifier {
  final OfflineDatabase database;
  bool isBusy = false;
  String? lastError;
  bool _disposed = false;

  OfflineDataProvider({OfflineDatabase? database})
    : database = database ?? OfflineDatabase.instance;

  Future<File> backupTo(File destination) async {
    return _run(() => database.exportBackup(destination));
  }

  Future<int> restoreFrom(File source) async {
    return _run(() async {
      final count = await database.importBackup(source);
      await ProductStore.instance.reload();
      return count;
    });
  }

  Future<T> _run<T>(Future<T> Function() operation) async {
    isBusy = true;
    lastError = null;
    if (!_disposed) notifyListeners();
    try {
      return await operation();
    } catch (error) {
      lastError = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
