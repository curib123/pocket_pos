import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Helper/AppCategory.dart';
import 'package:animate_do/animate_do.dart';

class CategoryList extends StatelessWidget {
  final List<String> categories;

  const CategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icon = StoreCategory.icons[category] ?? LucideIcons.tag;
        final color = StoreCategory.colors[category] ?? Colors.grey;

        return FadeInLeft(
          duration: const Duration(milliseconds: 300),
          child: ListTile(
            onTap: () {
              // Navigate to products under this category
            },
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColor.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Available Product : 0',
              style: TextStyle(
                fontSize: 13,
                color: AppColor.textSecondary,
              ),
            ),
            trailing: const Icon(
              LucideIcons.chevronRight,
              color: AppColor.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.80,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final icon = StoreCategory.icons[category] ?? LucideIcons.tag;
          final color = StoreCategory.colors[category] ?? Colors.grey;

          return GestureDetector(
            onTap: () {
              // Navigate to products under this category
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColor.border.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Available Product: 0',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
