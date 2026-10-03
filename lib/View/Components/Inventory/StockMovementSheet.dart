import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';

enum StockMovementType { stockIn, stockOut, adjustment }

extension StockMovementTypeUi on StockMovementType {
  String get label => switch (this) {
        StockMovementType.stockIn => 'Stock In',
        StockMovementType.stockOut => 'Stock Out',
        StockMovementType.adjustment => 'Adjust',
      };

  String get helper => switch (this) {
        StockMovementType.stockIn => 'Add newly received stock.',
        StockMovementType.stockOut =>
          'Remove stock that left the shelf. Inventory cannot go below zero.',
        StockMovementType.adjustment =>
          'Enter the actual physical count to correct the system quantity.',
      };

  IconData get icon => switch (this) {
        StockMovementType.stockIn => Icons.add_rounded,
        StockMovementType.stockOut => Icons.remove_rounded,
        StockMovementType.adjustment => Icons.tune_rounded,
      };
}

class StockMovementSheet extends StatefulWidget {
  final StockMovementType type;
  final Product? initialProduct;

  const StockMovementSheet({
    super.key,
    required this.type,
    this.initialProduct,
  });

  static Future<void> show(
    BuildContext context, {
    required StockMovementType type,
    Product? product,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StockMovementSheet(type: type, initialProduct: product),
    );
  }

  @override
  State<StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends State<StockMovementSheet> {
  final _quantityController = TextEditingController();
  String? _selectedProductId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProduct?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().getAllProductsWithVariants();
    final selected = _selectedProduct(products);
    final currentCount = selected?.totalQuantity ?? 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppBrand.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.type.icon, color: AppBrand.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.type.helper,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppBrand.muted,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Product',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: products
                  .map(
                    (product) => DropdownMenuItem(
                      value: product.id,
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _selectedProductId = value),
            ),
            if (selected != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppBrand.primaryFaint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: AppBrand.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current stock',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppBrand.muted,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '$currentCount ${_unitLabel(selected)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _quantityController,
              enabled: !_saving,
              autofocus: widget.initialProduct != null,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.type == StockMovementType.adjustment
                    ? 'Physical count'
                    : 'Quantity',
                prefixIcon: Icon(
                  widget.type == StockMovementType.adjustment
                      ? Icons.fact_check_outlined
                      : Icons.numbers_rounded,
                ),
                helperText: widget.type == StockMovementType.adjustment
                    ? 'This replaces the current system count.'
                    : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving || products.isEmpty ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.type.icon),
                label: Text(_saving ? 'Saving…' : widget.type.label),
              ),
            ),
            if (products.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Add a product first before recording stock movement.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppBrand.muted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Product? _selectedProduct(List<Product> products) {
    final id = _selectedProductId;
    if (id == null) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  String _unitLabel(Product product) {
    final unit = product.unit?.trim();
    if (unit != null && unit.isNotEmpty) return unit;
    return product.isSoldByPiece && !product.isSoldByPack ? 'pcs' : 'units';
  }

  Future<void> _submit() async {
    final id = _selectedProductId;
    final quantity = int.tryParse(_quantityController.text.trim());

    if (id == null) {
      _showMessage('Choose a product.');
      return;
    }
    if (quantity == null ||
        (widget.type == StockMovementType.adjustment
            ? quantity < 0
            : quantity <= 0)) {
      _showMessage(
        widget.type == StockMovementType.adjustment
            ? 'Enter a valid physical count.'
            : 'Enter a quantity greater than zero.',
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<ProductStockProvider>();

    final result = switch (widget.type) {
      StockMovementType.stockIn => await provider.stockIn(
          productId: id,
          quantity: quantity,
        ),
      StockMovementType.stockOut => await provider.stockOut(
          productId: id,
          quantity: quantity,
        ),
      StockMovementType.adjustment => await provider.adjustStock(
          productId: id,
          actualStock: quantity,
          reason: 'Physical count correction',
        ),
    };

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      _showMessage(result.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
