import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import 'package:paninda/View/Screens/ProductList/category_product_list_screen.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/Core/product_metrics_container.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool isArchiveView = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    final provider = Provider.of<ProductProvider>(context, listen: false);
    Future.delayed(Duration.zero, () async {
      await provider.syncProductsWithServer();
      await provider.insertOrUpdateProductsToDatabase();
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScalableAppBar(
        isTitle: false,
        showSearchBar: true,
        title: "Product",
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: Column(
              children: [
                /// Metrics with animation
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    final totalProducts = provider.totalProductsLength;
                    final stockInHand = provider.totalStocksQuantity.toStringAsFixed(2);
                    final productChange = provider.productCountChangePercent.toStringAsFixed(1);
                    final stockChange = provider.quantityChangePercent.toStringAsFixed(1);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: FadeIn(
                          duration: const Duration(milliseconds: 600),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ProductMetricsContainer(
                                heading: "Total Products",
                                value: "$totalProducts",
                                percentage: "${productChange.startsWith('-') ? '' : '+'}$productChange%",
                              ),
                              const SizedBox(width: 12),
                              ProductMetricsContainer(
                                heading: "Stock in Hand",
                                value: "$stockInHand",
                                percentage: "${stockChange.startsWith('-') ? '' : '+'}$stockChange%",
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Product Category",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColor.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isArchiveView = !isArchiveView;
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: AppColor.surface,
                              ),
                              child: Text(isArchiveView ? 'Hide Archives' : 'View Archives'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                /// Category List with animations
                /// Category List with animations
                Expanded(
                  child: Consumer2<ProductProvider, StoreCategoryProvider>(
                    builder: (context, productProvider, storeCategoryProvider, _) {
                      final categories = !isArchiveView
                          ? storeCategoryProvider.visibleCategories
                          : storeCategoryProvider.hiddenCategories;

                      return Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              final offsetAnimation = Tween<Offset>(
                                begin: const Offset(0, -0.2),
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              key: ValueKey(isArchiveView),
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 2),
                              child: Text(
                                isArchiveView
                                    ? 'Swipe right to unhide categories →'
                                    : 'Swipe left to hide categories ←',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColor.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          if (categories.isEmpty)
                            Expanded(
                              child: Center(
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
                                        isArchiveView
                                            ? 'No hidden categories yet.'
                                            : 'No categories available.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColor.textSecondary.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isArchiveView
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
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final icon =
                                      StoreCategory.icons[category] ?? LucideIcons.tag;
                                  final color =
                                      StoreCategory.colors[category] ?? Colors.grey;
                                  final count = productProvider.getProductCountByCategory(category);
                                  final isHidden = storeCategoryProvider.isHidden(category);

                                  return FadeInLeft(
                                    duration: Duration(milliseconds: 300 + (index * 100)),
                                    child: Slidable(
                                      key: ValueKey(category),
                                      startActionPane: isHidden
                                          ? ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.25,
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) => storeCategoryProvider
                                                .setHidden(category, false),
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            icon: LucideIcons.eye,
                                          ),
                                        ],
                                      )
                                          : null,
                                      endActionPane: !isHidden
                                          ? ActionPane(
                                        motion: const ScrollMotion(),
                                        extentRatio: 0.25,
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) => storeCategoryProvider
                                                .setHidden(category, true),
                                            backgroundColor: Colors.redAccent,
                                            foregroundColor: Colors.white,
                                            icon: LucideIcons.eyeOff,
                                          ),
                                        ],
                                      )
                                          : null,
                                      child: Opacity(
                                        opacity: isHidden ? 0.3 : 1,
                                        child: ListTile(
                                          onTap: isHidden
                                              ? null
                                              : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CategoryProductListScreen(
                                                  category: category,
                                                ),
                                              ),
                                            );
                                          },
                                          contentPadding:
                                          const EdgeInsets.symmetric(vertical: 6),
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
                                          subtitle: Text(
                                            'All Product: $count',
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
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

              ],
            ),
          ),

          /// Add Product Button with animation
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: CustomButton(
                  color: AppColor.primary,
                  icon: LucideIcons.plusCircle,
                  label: "Add Product / Restock",
                  onPressed: () => AddProductModal.show(context,isStock: false,isEdit: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
