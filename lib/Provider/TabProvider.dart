import 'package:flutter/material.dart';
import 'package:nextpos/View/Screen/Main/DashBoardScreen.dart';
import 'package:nextpos/View/Screen/Main/ProductScreen.dart';
import 'package:nextpos/View/Screen/Main/ProfileScreen.dart';
import 'package:nextpos/View/Screen/Main/StockManagementScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isFirstTime = false;

  int get currentIndex => _currentIndex;
  bool get isFirstTime => _isFirstTime;

  final List<Widget> screens = const [
    DashBoardScreen(),
    ProductScreen(),
    StockManagementScreen(),
    ProfileScreen(),
  ];

  TabProvider() {
    loadFirstTimeStatus();
  }

  void setTab(int index) {
    if (index < 0 || index >= screens.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> loadFirstTimeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = prefs.getBool('first_time') ?? true;
    notifyListeners();
  }

  Future<void> setFirstTimeFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', value);
    _isFirstTime = value;
    notifyListeners();
  }
}
