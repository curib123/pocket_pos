import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppCategory.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';

class SetupCategoryScreen extends StatefulWidget {
  const SetupCategoryScreen({super.key});

  @override
  State<SetupCategoryScreen> createState() => _SetupCategoryScreenState();
}

class _SetupCategoryScreenState extends State<SetupCategoryScreen> {
  final Map<String, double> _pillWidths = {};

  double _generateWidth(String label) {
    if (_pillWidths.containsKey(label)) return _pillWidths[label]!;

    final rand = Random(label.hashCode);
    double width = 100 + rand.nextInt(60).toDouble(); // 100–160 px
    _pillWidths[label] = width;
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColor.primary;
    final sortedCategories = [...StoreCategory.all]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: sortedCategories.map((category) {
                    final isSelected = !provider.isHidden(category);
                    final width = _generateWidth(category);

                    return SizedBox(
                      width: width,
                      child: _PillToggle(
                        label: category,
                        isSelected: isSelected,
                        color: themeColor,
                        onTap: () => provider.toggleVisibility(category),
                      ),
                    );
                  }).toList(),
                );
              },
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
      splashColor: color.withOpacity(0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.25),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
