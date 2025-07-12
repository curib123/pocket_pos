import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Helper/AppCategory.dart';
import 'package:mobile_pos_inventory/View/Screen/ProductListScreen.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_pos_inventory/Provider/SwitchProvider.dart';
import 'package:animate_do/animate_do.dart';

class CategoryGrid extends StatelessWidget {
  final List<String> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, StoreCategoryProvider, SwitchProvider>(
      builder: (context, productProvider, storeCategoryProvider, switchProvider, _) {
        final isArchiveView = switchProvider.isArchiveView;

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
              final count = productProvider.getProductsByCategory(category).length.toString();

              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                child: Slidable(
                  key: ValueKey(category),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            storeCategoryProvider.setHidden(category, !isArchiveView);
                            final action = isArchiveView ? 'Unhidden' : 'Hidden';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$category has been $action')),
                            );
                          },
                          backgroundColor: isArchiveView ? Colors.green : Colors.redAccent,
                          foregroundColor: Colors.white,
                          icon: isArchiveView ? LucideIcons.eye : LucideIcons.eyeOff,
                          label: isArchiveView ? 'Unhide' : 'Hide',
                          flex: 2, // Make the button take up more space
                          spacing: 30, // More space between icon and label
                          autoClose: true,
                        ),
                      ],
                    ),

                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(category: category),
                        ),
                      );
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
                          Text(
                            'Available Product: $count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
