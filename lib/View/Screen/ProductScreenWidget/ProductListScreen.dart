import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Classes_Methods/helper_methods.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/Provider/SwitchProvider.dart';
import 'package:pocketpos/View/Components/Alert/showLoadingAndNotify.dart';
import 'package:pocketpos/View/Components/Widgets/BouncingCartIcon.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Modal/ProductDetailScreenModal.dart';
import 'package:pocketpos/View/Components/Modal/UpsertProductModal.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 15),
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

              return RefreshIndicator(
                onRefresh: () async {
                  await showLoadingAndNotify(context: context, task: () async => await autoSync(context));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 10),
                  child: Column(
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
                  ),
                ),
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
        double imageHeight = constraints.maxWidth < 500 ? 90 : 140;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 17,
            mainAxisSpacing: 20,
            childAspectRatio: 0.60,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isPack = product.isSoldByPack;
            final isPiece = product.isSoldByPiece;
            final hasStock = product.stocks.isNotEmpty;
            final lowStock =  product.totalQuantity <= 10;
            final outStock =  product.totalQuantity == 0;
            final stock = hasStock ? product.stocks.first : null;
            double baseFont = constraints.maxWidth < 500 ? 18 : 20;
            double fontSize = (baseFont - (product.name.length * 0.4)).clamp(12, baseFont).toDouble();

            return FadeInUp(
              duration: Duration(milliseconds: 250 + (index * 60)),
              child: GestureDetector(
                onTap: () => ProductDetailModal.show(context, product.id, false),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.secondarySurface),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.isVariant
                                    ? AppColor.warning
                                    : AppColor.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.isVariant ? 'Variant' : 'Main',
                                style:  TextStyle(
                                  color: Colors.white,
                                  fontSize: context.rf(12),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),

                      SizedBox(height: 5,),
                      // 🧾 Product Name
                      Shimmer.fromColors(
                          baseColor: AppColor.textPrimary ,
                          highlightColor: AppColor.accent,
                          period: Duration(seconds: 3),
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w900,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                        ),
                      ),
                      SizedBox(height: 5,),

                      ...(hasStock
                          ? [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPiece && !isPack)
                              Text(
                                '${currencyFormat.format(stock!.retailPrice)} / piece',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            if (isPack && !isPiece)
                              Text(
                                '${currencyFormat.format(stock!.retailPrice)} / pack',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            if (isPack && isPiece && (product.piecesPerPack ?? 0) > 0) ...[
                              Text(
                                '${currencyFormat.format(stock!.retailPrice)} / pack',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.rf(10),
                                ),
                              ),
                              Text(
                                '${currencyFormat.format(stock.retailPrice / product.piecesPerPack!)} / piece',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ]
                          : [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isPiece && !isPack)
                              Text(
                                '0.00 / piece',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            if (isPack && !isPiece)
                              Text(
                                '0.00 / pack',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            if (isPack && isPiece) ...[
                              Text(
                                '0.00 / pack',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: context.rf(10),
                                ),
                              ),
                              Text(
                                '0.00 / piece',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: context.rf(10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ]

                      ),

                      // 🏷 Selling types
                      if (isPack || isPiece)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -4,
                            alignment: WrapAlignment.center,
                            children: [
                              if (isPack) _buildTag('Pack',context),
                              if (isPiece) _buildTag('Piece',context),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stocks: ${product.totalQuantity}',
                            style:  TextStyle(
                              fontSize: context.rf(14),
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.w900
                            )

                          ),
                          if (outStock)
                            Icon(LucideIcons.alertTriangle,color: AppColor.errorText,size: 20,)
                          else if (lowStock)
                            Icon(LucideIcons.alertTriangle,color: AppColor.warning,size: 20,)
                        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth ~/ 350).clamp(1, 3);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2, // wide tile
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isPack = product.isSoldByPack;
            final isPiece = product.isSoldByPiece;
            final hasStock = product.stocks.isNotEmpty;
            final lowStock = product.totalQuantity <= 10;
            final outStock = product.totalQuantity == 0;
            final stock = hasStock ? product.stocks.first : null;
            double baseFont = constraints.maxWidth < 500 ? 18 : 20;
            double fontSize = (baseFont - (product.name.length * 0.4)).clamp(context.rf(12), baseFont).toDouble();

            return FadeInUp(
              duration: Duration(milliseconds: 250 + (index * 60)),
              child: GestureDetector(
                onTap: () => ProductDetailModal.show(context, product.id, false),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColor.secondarySurface),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ⬅️ Image & Badge
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: (product.imagePath != null &&
                                    product.imagePath!.isNotEmpty &&
                                    File(product.imagePath!).existsSync())
                                    ? Image.file(
                                  File(product.imagePath!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                    : _placeholderIcon(AppColor.primary, switchProvider),
                              ),
                              Positioned(
                                top: 0,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: product.isVariant ? AppColor.warning : AppColor.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.isVariant ? 'Variant' : 'Main',
                                    style:  TextStyle(
                                      color: Colors.white,
                                      fontSize: context.rf(12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // ➡️ Info Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🧾 Name
                                Shimmer.fromColors(
                                  baseColor: AppColor.textPrimary ,
                                  highlightColor: AppColor.accent,
                                  period: Duration(seconds: 3),
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w900,
                                      color: AppColor.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // 💰 Prices
                                ...(hasStock
                                    ? [
                                  if (isPiece && !isPack)
                                    Text('${currencyFormat.format(stock!.retailPrice)} / piece', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  if (isPack && !isPiece)
                                    Text('${currencyFormat.format(stock!.retailPrice)} / pack', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  if (isPack && isPiece && (product.piecesPerPack ?? 0) > 0) ...[
                                    Text('${currencyFormat.format(stock!.retailPrice)} / pack', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                    Text('${currencyFormat.format(stock.retailPrice / product.piecesPerPack!)} / piece', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  ],
                                ]
                                    : [
                                  if (isPiece && !isPack)
                                     Text('₱0.00 / piece', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  if (isPack && !isPiece)
                                     Text('₱0.00 / pack', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  if (isPack && isPiece) ...[
                                     Text('₱0.00 / pack', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                     Text('₱0.00 / piece', style: TextStyle(color: Colors.grey,fontSize: context.rf(10))),
                                  ],
                                ]),
                                const SizedBox(height: 6),

                                // 🏷 Tags
                                if (isPack || isPiece)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: -4,
                                    children: [
                                      if (isPack) _buildTag('Pack',context),
                                      if (isPiece) _buildTag('Piece',context),
                                    ],
                                  ),

                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5,),
                      // 📊 Stock Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stocks: ${product.totalQuantity}',
                            style:  TextStyle(
                              fontSize: context.rf(14),
                              color: AppColor.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (outStock)
                            const Icon(LucideIcons.alertTriangle, color: AppColor.errorText, size: 20)
                          else if (lowStock)
                            const Icon(LucideIcons.alertTriangle, color: AppColor.warning, size: 20),
                        ],
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

  Widget _placeholderIcon(Color color, SwitchProvider switchProvider) {
    return Container(
      width: switchProvider.isProductGridView ? double.infinity : 90,
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: color),
    );
  }
}

Widget _buildTag(String label,BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    margin: const EdgeInsets.symmetric( vertical: 3),
    decoration: BoxDecoration(
      color: AppColor.secondarySurface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: context.rf(11),
        fontWeight: FontWeight.w500,
        color: AppColor.textSecondary,
      ),
    ),
  );
}
