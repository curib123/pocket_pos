import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/View/Components/Modal/UpsertProductModal.dart';
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
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _ProductRow(product: products[index]),
                  ),
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
      onSelected: (_) => setState(() => _filter = value),
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

      final quantity = product.totalQuantity;
      return switch (_filter) {
        _InventoryFilter.all => true,
        _InventoryFilter.low => quantity > 0 && quantity <= 5,
        _InventoryFilter.out => quantity == 0,
      };
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _addProduct() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const UpsertProductModal(Category: 'Groceries'),
    );
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
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppBrand.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  product.name.isEmpty ? '?' : product.name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppBrand.primary,
                        fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 3),
                    Text(
                      product.category?.trim().isNotEmpty == true
                          ? product.category!
                          : 'Uncategorized',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.muted,
                          ),
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
                          color: quantity <= 5
                              ? AppBrand.primary
                              : AppBrand.ink,
                        ),
                  ),
                  Text(
                    quantity == 0 ? 'Out · $unit' : unit,
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
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${product.totalQuantity} currently in stock',
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
              title: 'Adjust',
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
          ],
        ),
      ),
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
