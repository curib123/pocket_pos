import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppCategory.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';

class SetupCategoryScreen extends StatelessWidget {
  const SetupCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColor.primary;
    final sortedCategories = [...StoreCategory.all]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: const Text('Setup Categories'),
        foregroundColor: themeColor,
      ),
      body: Consumer<StoreCategoryProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: sortedCategories.map((category) {
                final isSelected = !provider.isHidden(category);
                return _PillToggle(
                  label: category,
                  isSelected: isSelected,
                  color: themeColor,
                  onTap: () => provider.toggleVisibility(category),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _PillToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _PillToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
