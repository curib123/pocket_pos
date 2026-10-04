import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/View/Components/Brand/PocketInventoryBrand.dart';
import 'package:nextpos/View/Components/Inventory/ProductActivitySheet.dart';
import 'package:nextpos/View/Components/Inventory/ProductEditorSheet.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/View/Components/Widgets/AppDrawer.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum _InventoryFilter { all, low, out }

enum _InventoryLayout { list, grid }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  static const String _allCategories = 'All categories';

  _InventoryFilter _filter = _InventoryFilter.all;
  _InventoryLayout _layout = _InventoryLayout.list;
  String _category = _allCategories;
  int _page = 0;
  int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts =
        context.watch<ProductProvider>().getAllProductsWithVariants();
    final categories = <String>[
      _allCategories,
      ...allProducts
          .map((product) => product.category?.trim() ?? '')
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort(),
    ];
    final selectedCategory =
        categories.contains(_category) ? _category : _allCategories;
    final products = _applyFilters(allProducts, selectedCategory);
    final totalPages =
        products.isEmpty ? 1 : (products.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1).toInt();
    final start = safePage * _pageSize;
    final end = (start + _pageSize) > products.length
        ? products.length
        : start + _pageSize;
    final visibleProducts = products.sublist(start, end);
    final hasActiveFilters = _filter != _InventoryFilter.all ||
        selectedCategory != _allCategories;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 12,
        title: Row(
          children: [
            const PocketInventoryMark(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inventory',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    '${allProducts.length} products · Pocket Inventory',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppBrand.mutedOf(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search name, category, supplier or barcode',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _page = 0);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => setState(() => _page = 0),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showFilters(categories, selectedCategory),
                        icon: Icon(
                          Icons.tune_rounded,
                          color: hasActiveFilters
                              ? AppBrand.primary
                              : AppBrand.mutedOf(context),
                        ),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _filterSummary(selectedCategory),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<_InventoryLayout>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _InventoryLayout.list,
                          icon: Icon(Icons.view_agenda_outlined),
                          tooltip: 'List view',
                        ),
                        ButtonSegment(
                          value: _InventoryLayout.grid,
                          icon: Icon(Icons.grid_view_rounded),
                          tooltip: 'Grid view',
                        ),
                      ],
                      selected: {_layout},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _layout = selection.first;
                          _page = 0;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.mutedOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filter = _InventoryFilter.all;
                            _category = _allCategories;
                            _page = 0;
                          });
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? _EmptyInventory(
                    hasAnyProducts: allProducts.isNotEmpty,
                    onAddProduct: _addProduct,
                  )
                : _layout == _InventoryLayout.list
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                        itemCount: visibleProducts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, index) =>
                            _ProductRow(product: visibleProducts[index]),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.sizeOf(context).width >= 720 ? 3 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio:
                              MediaQuery.sizeOf(context).width >= 720
                                  ? .98
                                  : .72,
                        ),
                        itemCount: visibleProducts.length,
                        itemBuilder: (_, index) =>
                            _ProductGridCard(product: visibleProducts[index]),
                      ),
          ),
          if (products.isNotEmpty)
            _PaginationBar(
              page: safePage,
              pageSize: _pageSize,
              totalItems: products.length,
              totalPages: totalPages,
              onPrevious: safePage == 0
                  ? null
                  : () => setState(() => _page = safePage - 1),
              onNext: safePage >= totalPages - 1
                  ? null
                  : () => setState(() => _page = safePage + 1),
              onPageSizeChanged: (value) {
                setState(() {
                  _pageSize = value;
                  _page = 0;
                });
              },
            ),
        ],
      ),
    );
  }

  String _filterSummary(String selectedCategory) {
    final labels = <String>[];
    if (_filter == _InventoryFilter.low) labels.add('Low stock');
    if (_filter == _InventoryFilter.out) labels.add('Out of stock');
    if (selectedCategory != _allCategories) labels.add(selectedCategory);
    if (labels.isEmpty) return 'Filter products';
    if (labels.length == 1) return labels.first;
    return '${labels.length} filters active';
  }

  Future<void> _showFilters(
    List<String> categories,
    String selectedCategory,
  ) async {
    var pendingFilter = _filter;
    var pendingCategory = selectedCategory;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter inventory',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep the inventory screen focused. Filters stay here until you need them.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: AppBrand.mutedOf(sheetContext),
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Stock status',
                    style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in const [
                        (_InventoryFilter.all, 'All'),
                        (_InventoryFilter.low, 'Low stock'),
                        (_InventoryFilter.out, 'Out of stock'),
                      ])
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: pendingFilter == entry.$1,
                          showCheckmark: false,
                          onSelected: (_) => setSheetState(
                            () => pendingFilter = entry.$1,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Category',
                    style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map(
                          (category) => ChoiceChip(
                            label: Text(category),
                            selected: pendingCategory == category,
                            showCheckmark: false,
                            onSelected: (_) => setSheetState(
                              () => pendingCategory = category,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setSheetState(() {
                          pendingFilter = _InventoryFilter.all;
                          pendingCategory = _allCategories;
                        }),
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _filter = pendingFilter;
                            _category = pendingCategory;
                            _page = 0;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Apply filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Product> _applyFilters(
    List<Product> source,
    String selectedCategory,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.category ?? '').toLowerCase().contains(query) ||
          (product.supplierName ?? '').toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (selectedCategory != _allCategories &&
          product.category?.trim() != selectedCategory) {
        return false;
      }

      return switch (_filter) {
        _InventoryFilter.all => true,
        _InventoryFilter.low => product.isLowStock,
        _InventoryFilter.out => product.isOutOfStock,
      };
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _addProduct() {
    ProductEditorSheet.show(context);
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final quantity = product.totalQuantity;
    final unit = product.unit?.trim().isNotEmpty == true
        ? product.unit!.trim()
        : (product.isSoldByPiece && !product.isSoldByPack ? 'pcs' : 'units');
    final status = _stockStatus(context, product);
    final imagePath = product.imagePath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();
    final category = product.category?.trim().isNotEmpty == true
        ? product.category!.trim()
        : 'Uncategorized';
    final supplier = product.supplierName?.trim() ?? '';
    final sellingPrice = product.sellingPrice > 0
        ? '₱${product.sellingPrice.toStringAsFixed(2)}'
        : 'Price not set';

    return Material(
      color: AppBrand.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showActions(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppBrand.borderOf(context)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        color: status.background,
                        child: Text(
                          product.name.isEmpty
                              ? '?'
                              : product.name[0].toUpperCase(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: status.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.mutedOf(context),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplier.isEmpty ? 'Supplier not set' : 'Supplier: $supplier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.mutedOf(context),
                          ),
                    ),
                    const SizedBox(height: 7),
                    _StatusDotLabel(status: status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    sellingPrice,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: product.sellingPrice > 0
                              ? AppBrand.inkOf(context)
                              : AppBrand.mutedOf(context),
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$quantity $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppBrand.mutedOf(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final status = _stockStatus(context, product);
    final supplier = product.supplierName?.trim() ?? '';
    final cost = product.costPrice > 0
        ? '₱${product.costPrice.toStringAsFixed(2)}'
        : 'Not set';
    final sell = product.sellingPrice > 0
        ? '₱${product.sellingPrice.toStringAsFixed(2)}'
        : 'Not set';

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${product.totalQuantity} in stock · reorder at ${product.reorderLevel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppBrand.mutedOf(context),
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppBrand.primaryFaintOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.isEmpty ? 'Supplier not set' : 'Supplier: $supplier',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cost $cost · Selling $sell',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.mutedOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.add_rounded,
                title: 'Stock In',
                subtitle: 'Add received stock',
                onTap: () {
                  Navigator.pop(sheetContext);
                  StockMovementSheet.show(
                    context,
                    type: StockMovementType.stockIn,
                    product: product,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.remove_rounded,
                title: 'Stock Out',
                subtitle: 'Record stock leaving the shelf',
                onTap: () {
                  Navigator.pop(sheetContext);
                  StockMovementSheet.show(
                    context,
                    type: StockMovementType.stockOut,
                    product: product,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.tune_rounded,
                title: 'Adjustment',
                subtitle: 'Replace with the physical count',
                onTap: () {
                  Navigator.pop(sheetContext);
                  StockMovementSheet.show(
                    context,
                    type: StockMovementType.adjustment,
                    product: product,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.timeline_rounded,
                title: 'Product activity',
                subtitle: 'View Stock In, Stock Out, and adjustment timeline',
                onTap: () {
                  Navigator.pop(sheetContext);
                  ProductActivitySheet.show(
                    context,
                    product: product,
                  );
                },
              ),
              if (!product.isVariant)
                _ActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit details',
                  subtitle: 'Supplier, prices, photo, category and stock setup',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ProductEditorSheet.show(context, product: product);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  _StockStatus _stockStatus(BuildContext context, Product product) {
    if (product.isOutOfStock) {
      return _StockStatus(
        label: 'Out',
        color: AppBrand.danger,
        background: AppBrand.dangerSoftOf(context),
      );
    }
    if (product.isLowStock) {
      return _StockStatus(
        label: 'Low',
        color: AppBrand.warning,
        background: AppBrand.warningSoftOf(context),
      );
    }
    return _StockStatus(
      label: 'Healthy',
      color: AppBrand.primary,
      background: AppBrand.primarySoftOf(context),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final quantity = product.totalQuantity;
    final status = _status(context);
    final imagePath = product.imagePath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();
    final supplier = product.supplierName?.trim() ?? '';
    final category = product.category?.trim().isNotEmpty == true
        ? product.category!.trim()
        : 'Uncategorized';
    final unit = product.unit?.trim().isNotEmpty == true
        ? product.unit!.trim()
        : 'units';

    return Material(
      color: AppBrand.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _ProductRow(product: product)._showActions(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppBrand.borderOf(context)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: hasImage
                        ? Image.file(
                            File(imagePath),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            color: status.background,
                            child: Text(
                              product.name.isEmpty
                                  ? '?'
                                  : product.name[0].toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: status.color,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppBrand.mutedOf(context),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                supplier.isEmpty ? 'Supplier not set' : supplier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppBrand.mutedOf(context),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                product.sellingPrice > 0
                    ? '₱${product.sellingPrice.toStringAsFixed(2)}'
                    : 'Price not set',
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: status.color,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '$quantity $unit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    'Reorder ${product.reorderLevel}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppBrand.mutedOf(context),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StockStatus _status(BuildContext context) {
    if (product.isOutOfStock) {
      return _StockStatus(
        label: 'Out',
        color: AppBrand.danger,
        background: AppBrand.dangerSoftOf(context),
      );
    }
    if (product.isLowStock) {
      return _StockStatus(
        label: 'Low',
        color: AppBrand.warning,
        background: AppBrand.warningSoftOf(context),
      );
    }
    return _StockStatus(
      label: 'Healthy',
      color: AppBrand.primary,
      background: AppBrand.primarySoftOf(context),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppBrand.primarySoftOf(context),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppBrand.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  const _PaginationBar({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (page * pageSize) + 1;
    final calculatedEnd = (page + 1) * pageSize;
    final end = calculatedEnd > totalItems ? totalItems : calculatedEnd;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        decoration: BoxDecoration(
          color: AppBrand.surfaceOf(context),
          border: Border(
            top: BorderSide(color: AppBrand.borderOf(context)),
          ),
        ),
        child: Row(
          children: [
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [10, 25, 50]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('$value / page'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onPageSizeChanged(value);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$start–$end of $totalItems',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppBrand.mutedOf(context),
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Previous page',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${page + 1}/$totalPages',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockStatus {
  final String label;
  final Color color;
  final Color background;

  const _StockStatus({
    required this.label,
    required this.color,
    required this.background,
  });
}

class _StatusDotLabel extends StatelessWidget {
  final _StockStatus status;

  const _StatusDotLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status.color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StockStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  final bool hasAnyProducts;
  final VoidCallback onAddProduct;

  const _EmptyInventory({
    required this.hasAnyProducts,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppBrand.primarySoftOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppBrand.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyProducts ? 'No matching products' : 'Your inventory is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyProducts
                  ? 'Try another search or stock filter.'
                  : 'Add your first product, then use Stock In to record what is on the shelf.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppBrand.mutedOf(context),
                  ),
            ),
            if (!hasAnyProducts) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add first product'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
