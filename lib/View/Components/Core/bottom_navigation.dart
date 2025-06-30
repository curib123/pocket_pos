import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColor.primary,
      unselectedItemColor: AppColor.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_rounded),
          label: 'Product',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_rounded),
          label: 'Loan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
