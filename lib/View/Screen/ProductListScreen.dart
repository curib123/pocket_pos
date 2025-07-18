import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/StoreCategoryProvider.dart';
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
  Timer? _debounce;
  String _searchQuery = '';
  int _loadedCount = 50;
  final int _loadIncrement = 50;

// Dropdown filter state:
  String _selectedCategoryFilter =  'All';
  String _selectedSort = 'Newest';
  String _selectedStockStatus = 'All';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.category.isNotEmpty ? _selectedCategoryFilter = widget.category : _selectedCategoryFilter = 'All';
  }


  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // <--- Important for preventing overflow
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(
              e,
              overflow: TextOverflow.ellipsis, // Avoids overflow for long text
              style:  TextStyle(fontSize: 14,color: Colors.grey,fontWeight: FontWeight.w300),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: _dropdownDecoration(label),
        style: const TextStyle(fontSize: 12),
      ),
    );
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
                      maxChildSize: 0.8,
                      initialChildSize: 0.7,
                      minChildSize: 0.65,
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
          body: Consumer2<SwitchProvider,StoreCategoryProvider>(
            builder: (context, switchProvider,storeCategoryProvider, _) {
              final allProducts = widget.category.isNotEmpty
                  ? productProvider.getAllProductsWithVariantsByCategory(widget.category)
                  : productProvider.getAllProductsWithVariants();

              // Start with all products
              List<Product> filteredProducts = allProducts;

                    // Apply search query filter
              if (_searchQuery.isNotEmpty) {
                filteredProducts = filteredProducts.where((p) {
                  return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();
              }

                // Apply category filter
              if (_selectedCategoryFilter != 'All') {
                filteredProducts = filteredProducts.where((p) => p.category == _selectedCategoryFilter).toList();
              }

                 // Apply stock status filter
              if (_selectedStockStatus == 'In Stock') {
                filteredProducts = filteredProducts.where((p) => p.totalQuantity > 0).toList();
              } else if (_selectedStockStatus == 'Out of Stock') {
                filteredProducts = filteredProducts.where((p) => p.totalQuantity == 0).toList();
              } else if (_selectedStockStatus == 'Low Stock') {
                filteredProducts = filteredProducts.where((p) => p.totalQuantity > 0 && p.totalQuantity <= 10).toList();
              }

                // Debug print
              for (var p in filteredProducts) {
                print('[Filtered Product] ${p.name} - Total Quantity: ${p.totalQuantity}');
              }




              // Sort logic
              if (_selectedSort == 'Newest') {
                filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              } else if (_selectedSort == 'Oldest') {
                filteredProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              } else if (_selectedSort == 'Price ↑') {
                filteredProducts.sort((a, b) {
                  final aLowestPrice = a.stocks.isNotEmpty
                      ? a.stocks.map((s) => s.retailPrice).reduce((x, y) => x < y ? x : y)
                      : 0;
                  final bLowestPrice = b.stocks.isNotEmpty
                      ? b.stocks.map((s) => s.retailPrice).reduce((x, y) => x < y ? x : y)
                      : 0;
                  return aLowestPrice.compareTo(bLowestPrice);
                });
              } else if (_selectedSort == 'Price ↓') {
                filteredProducts.sort((a, b) {
                  final aLowestPrice = a.stocks.isNotEmpty
                      ? a.stocks.map((s) => s.retailPrice).reduce((x, y) => x < y ? x : y)
                      : 0;
                  final bLowestPrice = b.stocks.isNotEmpty
                      ? b.stocks.map((s) => s.retailPrice).reduce((x, y) => x < y ? x : y)
                      : 0;
                  return bLowestPrice.compareTo(aLowestPrice);
                });
              }


              final visibleProducts = filteredProducts.take(_loadedCount).toList();

              return Column(
                children: [
                  // Search Bar
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
                                    _loadedCount = 50;
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
                              switchProvider.isProductGridView
                                  ? Icons.layers_rounded
                                  : Icons.dashboard_rounded,
                              size: 30,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter Dropdowns
                  FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double spacing = 12;
                          double itemWidth = (constraints.maxWidth - (spacing * 2)) / (widget.category.isNotEmpty ? 2 : 3);

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 10,
                            children: [
                           if(widget.category.isEmpty) _buildFilterDropdown(
                            width: itemWidth,
                            label: 'Category',
                            value: _selectedCategoryFilter,
                            items: ['All', ...storeCategoryProvider.visibleCategories.toList()],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryFilter = value!;
                                _loadedCount = 50;
                              });
                            },
                            ),
                              _buildFilterDropdown(
                                width: itemWidth,
                                label: 'Sort',
                                value: _selectedSort,
                                items: ['Newest', 'Oldest', 'Price ↑', 'Price ↓', 'Quantity ↑', 'Quantity ↓'],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSort = value!;
                                  });
                                },
                              ),
                              _buildFilterDropdown(
                                width: itemWidth,
                                label: 'Stock',
                                value: _selectedStockStatus,
                                items: ['All', 'In Stock', 'Out of Stock', 'Low Stock'],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStockStatus = value!;
                                  });
                                },
                              ),

                            ],
                          );
                        },
                      ),
                    ),
                  ),




                  // Product List/Grid
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                            _loadedCount < filteredProducts.length) {
                          setState(() {
                            _loadedCount += _loadIncrement;
                          });
                        }
                        return false;
                      },
                      child: visibleProducts.isEmpty
                          ? _buildEmptyState()
                          : switchProvider.isProductGridView
                          ? _buildGridView(visibleProducts, currencyFormat, switchProvider)
                          : _buildListView(visibleProducts, currencyFormat, switchProvider),
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
                                    ? AppColor.warning.withOpacity(0.8)
                                    : AppColor.success.withOpacity(0.9),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Stocks: ${product.totalQuantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColor.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          maxWidth: 150, // 👈 Optional: constrain width to make ellipsis work
                        ),
                        child: Text(
                          '${currencyFormat.format(price)}',
                          style: TextStyle(
                            fontSize: priceFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
