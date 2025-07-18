import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_stock_inventory/Provider/SwitchProvider.dart';
import 'package:mobile_stock_inventory/View/Components/BouncingCartIcon.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomFlatDropdown.dart';
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
              } // Apply product type filter (MAIN or VARIANT only)
              if (_selectedStockStatus == 'Main Stock') {
                filteredProducts = filteredProducts.where((p) => !p.isVariant).toList();
              } else if (_selectedStockStatus == 'Variant Stock') {
                filteredProducts = filteredProducts.where((p) => p.isVariant).toList();
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
              } else if (_selectedSort == 'Alphabetical') {
                filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              }



              final visibleProducts = filteredProducts.take(_loadedCount).toList();

              return Column(
                children: [
                  // Search Bar
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                          int columnCount = widget.category.isNotEmpty ? 2 : 3;
                          double itemWidth = (constraints.maxWidth - (spacing * (columnCount - 1))) / columnCount;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: 10,
                            children: [

                              if (widget.category.isEmpty)
                                SizedBox(
                                  width: itemWidth,
                                  child: CustomFlatDropdown<String>(
                                    hint: 'Select Category',
                                    value: _selectedCategoryFilter,
                                    items: ['All', ...storeCategoryProvider.visibleCategories.toList()],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategoryFilter = value!;
                                        _loadedCount = 50;
                                      });
                                    },
                                    itemBuilder: (val) => Text(val),
                                  ),
                                ),

                              // Sort Filter
                              SizedBox(
                                width: itemWidth,
                                child: CustomFlatDropdown<String>(
                                  hint: 'Select Sort',
                                  value: _selectedSort,
                                  items: ['Newest', 'Oldest', 'Price ↑', 'Price ↓', 'Quantity ↑', 'Quantity ↓','Alphabetical'],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSort = value!;
                                    });
                                  },
                                  itemBuilder: (val) => Text(val),
                                ),
                              ),

                              // Stock Filter
                              SizedBox(
                                width: itemWidth,
                                child: CustomFlatDropdown<String>(
                                  hint: 'Select Stock Status',
                                  value: _selectedStockStatus,
                                  items: ['All', 'In Stock', 'Out of Stock', 'Low Stock','Main Stock','Variant Stock'],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStockStatus = value!;
                                    });
                                  },
                                  itemBuilder: (val) => Text(val),
                                ),
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

  Widget _buildGridView(List<Product> products, currencyFormat, SwitchProvider switchProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth ~/ 160).clamp(2, 6);
        double imageHeight = constraints.maxWidth < 500 ? 100 : 140;
        double fontSize = constraints.maxWidth < 500 ? 12 : 14;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 17,
            mainAxisSpacing: 20,
            childAspectRatio: 0.65,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isPack = product.isSoldByPack;
            final isPiece = product.isSoldByPiece;
            final hasStock = product.stocks.isNotEmpty;
            final stock = hasStock ? product.stocks.first : null;

            return FadeInUp(
              duration: Duration(milliseconds: 250 + (index * 60)),
              child: GestureDetector(
                onTap: () => ProductDetailModal.show(context, product.id, false),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.035),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.border.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 📸 Image + Price + Badge
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
                              fit: BoxFit.cover,
                            )
                                : _placeholderIcon(AppColor.primary, switchProvider),
                          ),

                          // 🟧 Variant / Main Badge
                          Positioned(
                            top: 0,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: product.isVariant
                                    ? AppColor.warning.withOpacity(0.9)
                                    : AppColor.success.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.isVariant ? 'Variant' : 'Main',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // 💰 Price (stacked inside image)
                          if (hasStock && (isPack || isPiece))
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isPiece && !isPack)
                                    _buildImagePriceTag(
                                      '${currencyFormat.format(stock!.retailPrice)} / piece',
                                    ),
                                  if (isPiece && isPack && (product.piecesPerPack ?? 0) > 0)
                                    _buildImagePriceTag(
                                      '${currencyFormat.format(stock!.retailPrice / product.piecesPerPack!)} / piece',
                                    ),
                                  if (isPack)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _buildImagePriceTag(
                                        '${currencyFormat.format(stock!.retailPrice)} / pack',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🏷 Selling types
                      if (isPack || isPiece)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -4,
                            alignment: WrapAlignment.center,
                            children: [
                              if (product.category != null) _buildTag(product.category!),
                              if (isPack) _buildTag('Pack'),
                              if (isPiece) _buildTag('Piece'),
                            ],
                          ),
                        ),

                      // 🧾 Product Name
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,

                      ),

                      const SizedBox(height: 3),

                      // 📊 Stock
                      Text(
                        'Stocks: ${product.totalQuantity}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColor.textSecondary,
                        ),
                        textAlign: TextAlign.center,
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

  Widget buildSlimProductTile(Product product, NumberFormat currencyFormat, BuildContext context) {
    final hasStock = product.stocks.isNotEmpty;
    final stock = hasStock ? product.stocks.first : null;
    final isPack = product.isSoldByPack;
    final isPiece = product.isSoldByPiece;
    final hasImage = product.imagePath?.isNotEmpty == true && File(product.imagePath!).existsSync();

    return InkWell(
      onTap: () => ProductDetailModal.show(context, product.id, false),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.accent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // 🖼️ Image or Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: hasImage
                  ? Image.file(
                File(product.imagePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 48,
                height: 48,
                color: AppColor.accent.withOpacity(0.1),
                child: const Icon(Icons.inventory_2_rounded, color: AppColor.accent),
              ),
            ),
            const SizedBox(width: 10),

            // 📝 Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColor.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),
                  // 🏷 Selling types
                  if (isPack || isPiece)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: -4,
                        alignment: WrapAlignment.center,
                        children: [
                          if (product.category != null) _buildTag(product.category!),
                          if (product.isVariant) _buildTag('Variant'),
                          if (!product.isVariant) _buildTag('Main'),
                          if (isPack) _buildTag('Pack'),
                          if (isPiece) _buildTag('Piece'),
                        ],
                      ),
                    ),

                  // Prices
                  if (hasStock && (isPack || isPiece))
                    Wrap(
                      spacing: 6,
                      runSpacing: -2,
                      children: [
                        if (isPack)
                          _priceChip('${currencyFormat.format(stock!.retailPrice)} / pack'),
                        if (isPiece)
                          _priceChip(() {
                            if (!isPack) {
                              return '${currencyFormat.format(stock!.retailPrice)} / piece';
                            } else if ((product.piecesPerPack ?? 0) > 0) {
                              return '${currencyFormat.format(stock!.retailPrice / product.piecesPerPack!)} / piece';
                            } else {
                              return '—';
                            }
                          }()),
                      ],
                    ),
                   const SizedBox(height: 5,),
                  // Stock
                  Text(
                    'Stock: ${product.totalQuantity}',
                    style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                  ),
                ],
              ),
            ),

            // ➡️ Arrow
            const Icon(Icons.chevron_right_rounded, color: AppColor.textSecondary),
          ],
        ),
      ),
    );
  }
  Widget _priceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildListView(List<Product> products, currencyFormat, context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return buildSlimProductTile(products[index], currencyFormat, context);
      },
    );
  }



  Widget _buildImagePriceTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    margin: const EdgeInsets.symmetric( vertical: 3),
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
