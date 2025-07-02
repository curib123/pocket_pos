import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
          icon: Icon(LucideIcons.layoutDashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.boxes),
          label: 'Product',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.wallet),
          label: 'Loan',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.store),
          label: 'Profile',
        ),
      ],
    );
  }
}
