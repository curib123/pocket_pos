import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_pos_inventory/Provider/SwitchProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Helper/AppCategory.dart';
import 'package:mobile_pos_inventory/View/Screen/ProductListScreen.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';

class CategoryList extends StatefulWidget {
  final List<String> categories;

  const CategoryList({super.key, required this.categories});

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late List<String> visibleCategories;

  @override
  void initState() {
    super.initState();
    visibleCategories = List.from(widget.categories);
  }

  @override
  void didUpdateWidget(covariant CategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories) {
      setState(() {
        visibleCategories = List.from(widget.categories);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, StoreCategoryProvider,SwitchProvider>(
      builder: (context, productProvider, storeCategoryProvider,switchProvider, _) {
        final isArchiveView = switchProvider.isArchiveView;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          itemCount: visibleCategories.length,
          itemBuilder: (context, index) {
            final category = visibleCategories[index];
            final icon = StoreCategory.icons[category] ?? LucideIcons.tag;
            final color = StoreCategory.colors[category] ?? Colors.grey;
            final count = productProvider.getProductsByCategory(category).length.toString();

            return FadeInLeft(
              duration: const Duration(milliseconds: 300),
              child: Slidable(
                key: ValueKey(category),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        storeCategoryProvider.setHidden(category, !isArchiveView);
                      },
                      backgroundColor: isArchiveView ? Colors.green : Colors.redAccent,
                      foregroundColor: Colors.white,
                      icon: isArchiveView ? LucideIcons.eye : LucideIcons.eyeOff,
                      label: isArchiveView ? 'Unhide' : 'Hide',
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(category: category),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
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
                  subtitle: Text(
                    'Available Product: $count',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
