import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/SwitchProvider.dart';
import 'package:mobile_stock_inventory/View/Components/BouncingCartIcon.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Modal/ProductDetailScreenModal.dart';
import 'package:mobile_stock_inventory/View/Components/Modal/UpsertProductModal.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({super.key, required this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  Timer? _debounce;
  int _loadedCount = 50;
  final int _loadIncrement = 50;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(child: Text(widget.category.isNotEmpty ? widget.category : "All Product List")),
                BouncingCartIcon()
              ],
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CustomButton(
              text: "Add Product",
              icon: LucideIcons.plus,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  builder: (context) {
                    return DraggableScrollableSheet(
                      expand: false,
                      maxChildSize: 0.95,
                      initialChildSize: 0.9,
                      minChildSize: 0.6,
                      builder: (_, controller) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Material(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          color: Colors.white,
                          child: SafeArea(
                            top: false,
                            child: SingleChildScrollView(
                              controller: controller,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              child: UpsertProductModal(Category: widget.category,), // put your form here
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );



              },
            ),
          ),
          body: Consumer<SwitchProvider>(
            builder: (context, switchProvider, _) {
              // All filtering logic
              final allFiltered = widget.category.isNotEmpty
                  ? productProvider.getAllProductsWithVariantsByCategory(widget.category).where(
                    (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              ).toList()
                  : productProvider.getAllProductsWithVariants().where(
                    (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              ).toList();

              final filtered = allFiltered.take(_loadedCount).toList();

              return Column(
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search product...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                if (_debounce?.isActive ?? false) _debounce!.cancel();
                                _debounce = Timer(const Duration(milliseconds: 300), () {
                                  setState(() {
                                    _searchQuery = value;
                                    _loadedCount = 50; // Reset pagination
                                  });
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              switchProvider.toggleProductGridView();
                            },
                            icon: Icon(
                              switchProvider.isProductGridView ? Icons.layers_rounded : Icons.dashboard_rounded,
                              size: 30,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                            _loadedCount < allFiltered.length) {
                          setState(() {
                            _loadedCount += _loadIncrement;
                          });
                        }
                        return false;
                      },
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : switchProvider.isProductGridView
                          ? _buildGridView(filtered, currencyFormat, switchProvider)
                          : _buildListView(filtered, currencyFormat, switchProvider),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInDown(
        duration: const Duration(milliseconds: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageSearch, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Try a different name or category', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Product> products, currencyFormat, SwitchProvider switchProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth ~/ 160).clamp(2, 6);
        double imageHeight = constraints.maxWidth + 50 < 500 ? 110 : 150;
        double fontSize = constraints.maxWidth < 500 ? 13 : 14;
        double priceFontSize = constraints.maxWidth < 500 ? 13 : 14.5;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.60,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isPack = product.isSoldByPack;
            final isPiece = product.isSoldByPiece;
            final unit = isPack ? (product.unit ?? 'pack') : 'pcs';
            final price = product.stocks.isNotEmpty
                ? product.stocks.first.retailPrice
                : 0;

            print(product.isVariant);

            return FadeInUp(
              duration: Duration(milliseconds: 250 + (index * 60)),
              child: GestureDetector(
                onTap: () {
                  ProductDetailModal.show(context, product.id,false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.035),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (product.imagePath != null &&
                                product.imagePath!.isNotEmpty &&
                                File(product.imagePath!).existsSync())
                                ? Image.file(
                              File(product.imagePath!),
                              width: double.infinity,
                              height: imageHeight,
                              fit: BoxFit.fill,
                            )
                                : _placeholderIcon(AppColor.primary, switchProvider),
                          ),

                          // 🏷 Badge based on isVariant
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: product.isVariant == true
                                    ? AppColor.success.withOpacity(0.8)
                                    : AppColor.warning.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.isVariant == true ? 'Variant' : 'Main',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),


                      const SizedBox(height: 15),

                      // Tags
                      if (isPack || isPiece) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: -4,
                          alignment: WrapAlignment.center,
                          children: [
                            if (isPack) _buildTag('Pack'),
                            if (isPiece) _buildTag('Piece'),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Name
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 4),

                      // Stock
                      Text(
                        'Stocks: ${product.totalQuantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColor.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 5),

                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${currencyFormat.format(price)} | $unit',
                          style: TextStyle(
                            fontSize: priceFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildListView(List<Product> products, currencyFormat, SwitchProvider switchProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl = product.imagePath ?? '';
        final isPack = product.isSoldByPack;
        final isPiece = product.isSoldByPiece;
        final unit = product.unit ?? "unit" ;
        final price = product.stocks.isNotEmpty
            ? product.stocks.first.retailPrice
            : 0;

        return FadeInUp(
          duration: Duration(milliseconds: 200 + (index * 60)),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              tileColor: AppColor.accent.withOpacity(0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: imageUrl.isNotEmpty && File(imageUrl).existsSync()
                    ? Image.file(
                  File(imageUrl),
                  width: 60,
                  height: 100,
                  fit: BoxFit.cover,
                )
                    : _placeholderIcon(AppColor.accent, switchProvider),
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColor.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  // Selling Type Tags
                  if (isPack || isPiece) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: -4,
                      children: [
                        if (isPack) _buildTag('Pack'),
                        if (isPiece) _buildTag('Piece'),
                      ],
                    ),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price + unit
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currencyFormat.format(price),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '| $unit',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Stock Info
                    Text(
                      'Stocks: ${product.totalQuantity}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColor.textSecondary,
                size: 30,
              ),
              onTap: () {
                ProductDetailModal.show(context,product.id,false);
              },
            ),
          ),
        );
      },
    );
  }




  Widget _placeholderIcon(Color color, SwitchProvider switchProvider) {
    return Container(
      width: switchProvider.isProductGridView ? double.infinity : 90,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: color),
    );
  }
}

Widget _buildTag(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColor.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColor.primary,
      ),
    ),
  );
}
