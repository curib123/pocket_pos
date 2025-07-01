import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';

class StoreCategoryProvider with ChangeNotifier {
  final Box visibilityBox = Hive.box('categoryVisibility');

  List<String> get visibleCategories =>
      StoreCategory.all.where((cat) => !isHidden(cat)).toList();

  List<String> get hiddenCategories =>
      StoreCategory.all.where((cat) => isHidden(cat)).toList();

  bool isHidden(String category) {
    return visibilityBox.get(category, defaultValue: false) as bool;
  }

  void setHidden(String category, bool hidden) {
    visibilityBox.put(category, hidden);
    notifyListeners();
  }

  void toggleVisibility(String category) {
    setHidden(category, !isHidden(category));
  }

  void showAll() {
    for (var category in StoreCategory.all) {
      visibilityBox.put(category, false);
    }
    notifyListeners();
  }
}
