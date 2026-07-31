import 'dart:io';

import 'package:flutter/foundation.dart';
import '../core/data/offline_database.dart';

/// Coordinates local backup/restore and exposes sync readiness to the UI.
class OfflineDataProvider extends ChangeNotifier {
  final OfflineDatabase database;
  bool isBusy = false;
  String? lastError;

  OfflineDataProvider({OfflineDatabase? database})
    : database = database ?? OfflineDatabase.instance;

  Future<File> backupTo(File destination) async {
    return _run(() => database.exportBackup(destination));
  }

  Future<int> restoreFrom(File source) async {
    return _run(() => database.importBackup(source));
  }

  Future<T> _run<T>(Future<T> Function() operation) async {
    isBusy = true;
    lastError = null;
    notifyListeners();
    try {
      return await operation();
    } catch (error) {
      lastError = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
