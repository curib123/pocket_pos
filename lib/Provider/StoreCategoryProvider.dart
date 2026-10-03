import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nextpos/Helper/Classes_Methods/AppCategory.dart';
import 'package:nextpos/core/data/offline_database.dart';

class StoreCategoryProvider with ChangeNotifier {
  StoreCategoryProvider({OfflineDatabase? database})
      : _database = database ?? OfflineDatabase.instance {
    unawaited(_load());
  }

  static const _prefix = 'category.hidden.';

  final OfflineDatabase _database;
  final Map<String, bool> _hidden = <String, bool>{};

  List<String> get visibleCategories =>
      StoreCategory.all.where((category) => !isHidden(category)).toList();

  List<String> get hiddenCategories =>
      StoreCategory.all.where(isHidden).toList();

  bool isHidden(String category) => _hidden[category] ?? false;

  Future<void> _load() async {
    final metadata = await _database.readAllMetadata();
    for (final category in StoreCategory.all) {
      _hidden[category] = metadata['$_prefix$category'] == 'true';
    }
    notifyListeners();
  }

  void setHidden(String category, bool hidden) {
    if ((_hidden[category] ?? false) == hidden) return;

    _hidden[category] = hidden;
    notifyListeners();
    unawaited(_database.setMetadata('$_prefix$category', hidden.toString()));
  }

  void toggleVisibility(String category) {
    setHidden(category, !isHidden(category));
  }

  void showAll() {
    var changed = false;
    for (final category in StoreCategory.all) {
      if (_hidden[category] == true) changed = true;
      _hidden[category] = false;
      unawaited(_database.setMetadata('$_prefix$category', 'false'));
    }
    if (changed) notifyListeners();
  }
}
