import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/View/Components/Inventory/ProductActivitySheet.dart';
import 'package:nextpos/View/Components/Inventory/ProductEditorSheet.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum _InventoryFilter { all, low, out }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  _InventoryFilter _filter = _InventoryFilter.all;
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
    final products = _applyFilters(allProducts);
    final totalPages =
        products.isEmpty ? 1 : (products.length / _pageSize).ceil();
    final safePage = _page.clamp(0, totalPages - 1).toInt();
    final start = safePage * _pageSize;
    final end = (start + _pageSize) > products.length
        ? products.length
        : start + _pageSize;
    final visibleProducts = products.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Add product',
            onPressed: _addProduct,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _page = 0);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => setState(() => _page = 0),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(_InventoryFilter.all, 'All'),
                      const SizedBox(width: 8),
                      _filterChip(_InventoryFilter.low, 'Low stock'),
                      const SizedBox(width: 8),
                      _filterChip(_InventoryFilter.out, 'Out of stock'),
                    ],
                  ),
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
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _ProductRow(product: visibleProducts[index]),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
    );
  }

  Widget _filterChip(_InventoryFilter value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _filter = value;
          _page = 0;
        });
      },
      selectedColor: AppBrand.primarySoft,
      backgroundColor: AppBrand.surface,
      side: BorderSide(
        color: selected ? AppBrand.primary : AppBrand.border,
      ),
      labelStyle: TextStyle(
        color: selected ? AppBrand.primary : AppBrand.ink,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  List<Product> _applyFilters(List<Product> source) {
    final query = _searchController.text.trim().toLowerCase();

    return source.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.category ?? '').toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);
      if (!matchesQuery) return false;

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
    final status = _stockStatus(product);
    final imagePath = product.imagePath;
    final hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return Material(
      color: AppBrand.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showActions(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppBrand.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 50,
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
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.category?.trim().isNotEmpty == true
                                ? product.category!
                                : 'Uncategorized',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppBrand.muted,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusDotLabel(status: status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: status.color,
                        ),
                  ),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppBrand.muted,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppBrand.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final status = _stockStatus(product);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                        color: AppBrand.muted,
                      ),
                ),
              ),
              const SizedBox(height: 18),
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
                  subtitle: 'Photo, reorder level, category, unit, or barcode',
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

  _StockStatus _stockStatus(Product product) {
    if (product.isOutOfStock) {
      return const _StockStatus(
        label: 'Out',
        color: AppBrand.danger,
        background: AppBrand.dangerSoft,
      );
    }
    if (product.isLowStock) {
      return const _StockStatus(
        label: 'Low',
        color: AppBrand.warning,
        background: AppBrand.warningSoft,
      );
    }
    return const _StockStatus(
      label: 'Healthy',
      color: AppBrand.primary,
      background: AppBrand.primarySoft,
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
          color: AppBrand.primarySoft,
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
        decoration: const BoxDecoration(
          color: AppBrand.surface,
          border: Border(top: BorderSide(color: AppBrand.border)),
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
                      color: AppBrand.muted,
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
                color: AppBrand.primarySoft,
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
                    color: AppBrand.muted,
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
