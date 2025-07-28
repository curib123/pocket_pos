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

    // Sort categories alphabetically
    final sortedCategories = [...StoreCategory.all]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Setup Categories'),
        foregroundColor: themeColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<StoreCategoryProvider>(
        builder: (context, provider, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Responsive crossAxisCount
              int crossAxisCount = constraints.maxWidth < 600
                  ? 2
                  : constraints.maxWidth < 900
                  ? 3
                  : 4;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: sortedCategories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.2, // Wider pills
                  ),
                  itemBuilder: (context, index) {
                    final category = sortedCategories[index];
                    final isVisible = !provider.isHidden(category);

                    return _GlowingPillToggle(
                      label: category,
                      isSelected: isVisible,
                      color: themeColor,
                      onTap: () => provider.toggleVisibility(category),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GlowingPillToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _GlowingPillToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ]
              : [],
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
