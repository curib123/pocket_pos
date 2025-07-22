import 'package:flutter/material.dart';
import 'package:retailpos/View/Screen/DashBoardScreen.dart';
import 'package:retailpos/View/Screen/ProductScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isFirstTime = false;

  int get currentIndex => _currentIndex;
  bool get isFirstTime => _isFirstTime;

  final List<Widget> screens = [
  DashBoardScreen(),
  ProductScreen(),
  DashBoardScreen(),
  DashBoardScreen(),
  ];

  TabProvider() {
    loadFirstTimeStatus();
  }

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// ✅ Only loads the value (does NOT change it)
  Future<void> loadFirstTimeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = prefs.getBool('first_time') ?? true;
    notifyListeners();
  }

  /// ✅ You must manually call this to change it.
  Future<void> setFirstTimeFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', value);
    _isFirstTime = value;
    notifyListeners();
  }
}
