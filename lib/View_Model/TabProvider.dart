import 'package:flutter/material.dart';
import 'package:paninda/View/Screens/Navigation/dashboard_screen.dart';
import 'package:paninda/View/Screens/Navigation/loan_screen.dart';
import 'package:paninda/View/Screens/Navigation/product_screen.dart';
import 'package:paninda/View/Screens/Navigation/settings_screen.dart';
class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final List<Widget> screens = [
    DashboardScreen(),
    ProductScreen(),
    LoanScreen(),
    SettingsScreen(),
  ];
}
