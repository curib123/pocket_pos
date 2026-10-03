import 'package:flutter/material.dart';
import 'package:nextpos/core/brand/app_brand.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final background = Color.alphaBlend(
      AppBrand.primary.withOpacity(
        baseTheme.brightness == Brightness.dark ? .86 : .94,
      ),
      baseTheme.colorScheme.surface,
    );
    final inactive = Colors.white.withOpacity(.66);

    return Theme(
      data: baseTheme.copyWith(
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          backgroundColor: background,
          indicatorColor: Colors.white.withOpacity(.15),
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white, size: 24);
            }
            return IconThemeData(color: inactive, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return baseTheme.textTheme.labelSmall?.copyWith(
              color: selected ? Colors.white : inactive,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
