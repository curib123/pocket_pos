import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/SwitchProvider.dart';
import 'package:mobile_stock_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/SearchAndCartRow.dart';
import 'package:mobile_stock_inventory/View/Screen/ProductListScreen.dart';
import 'package:mobile_stock_inventory/View/Screen/ProductScreenWidget/CategoryGrid.dart';
import 'package:mobile_stock_inventory/View/Screen/ProductScreenWidget/CategoryList.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, SwitchProvider, StoreCategoryProvider>(
      builder: (context, productProvider, switchProvider, storeCategoryProvider, _) {
        final categories = switchProvider.isArchiveView
            ? storeCategoryProvider.hiddenCategories
            : storeCategoryProvider.visibleCategories;

        return SafeArea(
          child: Scaffold(
            appBar: SearchAndCartAppBar(),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(10.0),
              child: CustomButton(
                text: "View All Product",
                icon: LucideIcons.box,
                onPressed: () {

                  Future.delayed(Duration.zero, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductListScreen(category: '',)),
                    );
                  });

                },
              ),
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Product Category",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                switchProvider.toggleArchiveView();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                backgroundColor: AppColor.primary,
                                foregroundColor: AppColor.surface,
                              ),
                              child: Text(
                                switchProvider.isArchiveView
                                    ? 'Show Categories'
                                    : 'Hide Categories',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0, -0.2),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(position: offsetAnimation, child: child),
                              );
                            },
                             child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                          child: Text(
                            switchProvider.isArchiveView
                                ? 'Swipe right to unhide categories →'
                                : 'Swipe left to hide categories ←',
                            key: ValueKey(switchProvider.isArchiveView), // ✅ Move key to Text
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColor.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ),

                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: categories.isEmpty
                            ? Center(
                          child: FadeIn(
                            duration: const Duration(milliseconds: 500),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.folderOpen,
                                  size: 60,
                                  color: AppColor.textSecondary.withOpacity(0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  switchProvider.isArchiveView
                                      ? 'No hidden categories yet.'
                                      : 'No categories available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColor.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  switchProvider.isArchiveView
                                      ? 'Switch back to view visible categories.'
                                      : 'Add new categories to get started.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColor.textSecondary.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                            : switchProvider.isCategoryGridView
                            ? CategoryList(
                          key: ValueKey('categoryList-${switchProvider.isArchiveView}'),
                          categories: categories,
                        )

                            : CategoryGrid(
                          key: ValueKey('CategoryGrid-${switchProvider.isArchiveView}'),
                          categories: categories,
                        )

                      ),
                    ],
                  ),
                ),

                /// Toggle View Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            switchProvider.toggleCategoryGridView();
                          },
                          icon: Icon(
                            switchProvider.isCategoryGridView
                                ? Icons.layers
                                : Icons.dashboard,
                            color: Colors.white,
                          ),
                          iconSize: 24,
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
        );
      },
    );
  }
}
