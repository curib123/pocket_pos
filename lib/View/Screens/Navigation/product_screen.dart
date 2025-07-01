import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:paninda/View/Screens/ProductList/category_product_list_screen.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:provider/provider.dart';
import 'package:paninda/View/Components/Core/product_metrics_container.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';
import 'package:paninda/View_Model/ProductProvider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool isGrid = false; // Only for toggling icon appearance


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
                /// Metrics
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    final totalProducts = provider.totalProductsLength;
                    final stockInHand = provider.totalStocksQuantity.toStringAsFixed(2);
                    final productChange = provider.productCountChangePercent.toStringAsFixed(1);
                    final stockChange = provider.quantityChangePercent.toStringAsFixed(1);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                    );
                  },
                ),

                /// List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                  child: Row(
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
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isGrid = !isGrid;
                          });
                        },
                        child: Icon(
                          isGrid ? Icons.archive_rounded : Icons.grid_view_rounded,
                          size: 24,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Only List View (GridView Removed)
                Expanded(
                  child: Consumer2<ProductProvider, StoreCategoryProvider>(
                    builder: (context, productProvider, storeCategoryProvider, _) {
                      final categories = !isGrid ? storeCategoryProvider.visibleCategories : storeCategoryProvider.hiddenCategories;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final icon = StoreCategory.icons[category] ?? Icons.category;
                          final color = StoreCategory.colors[category] ?? Colors.grey;
                          final count = productProvider.getProductCountByCategory(category);
                          final isHidden = storeCategoryProvider.isHidden(category);

                          return Slidable(
                            key: ValueKey(category),
                            startActionPane: isHidden
                                ? ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (_) =>
                                      storeCategoryProvider.setHidden(category, false),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  icon: Icons.visibility,
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
                                  onPressed: (_) =>
                                      storeCategoryProvider.setHidden(category, true),
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  icon: Icons.hide_source,
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
                                      builder: (_) =>
                                          CategoryProductListScreen(category: category),
                                    ),
                                  );
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
                                subtitle: Text(
                                  'All Product: $count',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          /// Add Product Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: CustomButton(
                color: AppColor.primary,
                icon: Icons.add_circle_rounded,
                label: "Add Product",
                onPressed: () => AddProductModal.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
