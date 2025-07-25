import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppCategory.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/View/Components/Custom/CustomPillToggle.dart';

class SetupCategoryScreen extends StatelessWidget {
  const SetupCategoryScreen({super.key});

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
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Consumer<StoreCategoryProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: sortedCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 👯 Two per row
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.5, // Adjust for pill size
              ),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                final isSelected = !provider.isHidden(category);

                return CustomPillToggle(
                  label: category,
                  isSelected: isSelected,
                  color: themeColor,
                  onTap: () => provider.toggleVisibility(category),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
