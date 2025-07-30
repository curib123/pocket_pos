import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppCategory.dart';
import 'package:pocketpos/View/Screen/ProductScreenWidget/ProductListScreen.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/Provider/SwitchProvider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class CategoryGrid extends StatelessWidget {
  final List<String> categories;

  const CategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, StoreCategoryProvider, SwitchProvider>(
      builder: (context, productProvider, storeCategoryProvider, switchProvider, _) {
        final isArchiveView = switchProvider.isArchiveView;

        final sortedCategories = List<String>.from(categories)
          ..sort((a, b) {
            final aCount = productProvider.getAllProductsWithVariantsByCategory(a).length;
            final bCount = productProvider.getAllProductsWithVariantsByCategory(b).length;
            if (bCount != aCount) {
              return bCount.compareTo(aCount);
            } else {
              return a.compareTo(b);
            }
          });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTablet = screenWidth > 600;

              // Set items per row based on device size
              final crossAxisCount = isTablet ? 3 : 2;

              // Padding + spacing setup
              const spacing = 16.0;
              const outerPadding = 16.0;
              final totalSpacing = spacing * (crossAxisCount - 1) + outerPadding * 2;

              final usableWidth = screenWidth - totalSpacing;
              final tileWidth = usableWidth / crossAxisCount;
              final tileHeight = tileWidth * 1.4; // make it a bit taller
              final aspectRatio = tileWidth / tileHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: outerPadding, vertical: 12),
                itemCount: sortedCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),

          itemBuilder: (context, index) {
                  final category = sortedCategories[index];
                  final icon = StoreCategory.icons[category] ?? LucideIcons.tag;
                  final color = StoreCategory.colors[category] ?? Colors.grey;
                  final count = productProvider.getAllProductsWithVariantsByCategory(category).length;

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
                            flex: 2,
                            spacing: 30,
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
                              color: AppColor.secondarySurface,
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
                              Shimmer.fromColors(
                                baseColor: AppColor.textPrimary,
                                highlightColor: AppColor.accent,
                                child: Text(
                                  category,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: context.rf(13),
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Available Product: $count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.rf(12),
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
              );
            },
          ),
        );
      },
    );
  }
}
