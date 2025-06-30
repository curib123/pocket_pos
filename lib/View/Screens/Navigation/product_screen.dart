import 'package:flutter/material.dart';
import 'package:paninda/View/Screens/ProductList/category_product_list_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isGrid = false;

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _toggleView() {
    setState(() {
      isGrid = !isGrid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(title: Text('Item 1')),
          ],
        ),
      ),
      appBar: ScalableAppBar(
        leading: GestureDetector(
          onTap: _openDrawer,
          child: const Icon(Icons.notes_rounded, size: 30),
        ),
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
                        onTap: _toggleView,
                        child: Icon(
                          isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                          size: 24,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Product Category List/Grid
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      if (isGrid) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 150, // <-- Fixed height
                              ),
                              itemCount: StoreCategory.all.length,
                              itemBuilder: (context, index) {
                                final category = StoreCategory.all[index];
                                final icon = StoreCategory.icons[category] ?? Icons.category;
                                final color = StoreCategory.colors[category] ?? Colors.grey;
                                final count = provider.getProductCountByCategory(category);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CategoryProductListScreen(category: category),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: color.withOpacity(0.2)),
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: color.withOpacity(0.1),
                                          radius: 24,
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          category,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColor.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'All Product: $count',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );

                      } else {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: StoreCategory.all.length,
                          itemBuilder: (context, index) {
                            final category = StoreCategory.all[index];
                            final icon = StoreCategory.icons[category] ?? Icons.category;
                            final color = StoreCategory.colors[category] ?? Colors.grey;
                            final count = provider.getProductCountByCategory(category);

                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryProductListScreen(category: category),
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
                            );
                          },
                        );
                      }
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
