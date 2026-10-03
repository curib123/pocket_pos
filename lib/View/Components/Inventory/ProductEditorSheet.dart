import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/StoreCategoryProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ProductEditorSheet extends StatefulWidget {
  final Product? product;

  const ProductEditorSheet({super.key, this.product});

  bool get isEditing => product != null;

  static Future<void> show(BuildContext context, {Product? product}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ProductEditorSheet(product: product),
    );
  }

  @override
  State<ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<ProductEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  final _initialStockController = TextEditingController(text: '0');

  String? _category;
  String _unit = 'pcs';
  bool _saving = false;

  static const _units = [
    'pcs',
    'pack',
    'bottle',
    'sachet',
    'box',
    'can',
    'kg',
    'liter',
  ];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _category = product?.category;
    final existingUnit = product?.unit?.trim();
    if (existingUnit != null && existingUnit.isNotEmpty) {
      _unit = existingUnit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<StoreCategoryProvider>();
    final categories = <String>{
      ...categoryProvider.visibleCategories,
      if (_category?.trim().isNotEmpty == true) _category!,
    }.toList()
      ..sort();

    if (_category == null && categories.isNotEmpty) {
      _category = categories.first;
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? 'Edit product' : 'Add product',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isEditing
                  ? 'Keep the details simple and easy to recognize on the shelf.'
                  : 'You only need the basics. Stock and activity can be updated anytime.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppBrand.muted,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              enabled: !_saving,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Product name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged:
                    _saving ? null : (value) => setState(() => _category = value),
              ),
            if (categories.isNotEmpty) const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _units.contains(_unit) ? _unit : 'pcs',
              decoration: const InputDecoration(
                labelText: 'Stock unit',
                prefixIcon: Icon(Icons.straighten_outlined),
              ),
              items: _units
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ),
                  )
                  .toList(),
              onChanged:
                  _saving ? null : (value) => setState(() => _unit = value ?? 'pcs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              enabled: !_saving,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Barcode (optional)',
                prefixIcon: Icon(Icons.qr_code_2_rounded),
              ),
            ),
            if (!widget.isEditing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _initialStockController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial stock',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  helperText: 'You can leave this at 0 and use Stock In later.',
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving
                      ? 'Saving…'
                      : widget.isEditing
                          ? 'Save changes'
                          : 'Add product',
                ),
              ),
            ),
            if (widget.isEditing && widget.product?.isVariant != true) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _archive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive product'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final initialStock = int.tryParse(_initialStockController.text.trim()) ?? 0;

    if (name.isEmpty) {
      _message('Enter a product name.');
      return;
    }
    if (initialStock < 0) {
      _message('Initial stock cannot be negative.');
      return;
    }

    final provider = context.read<ProductProvider>();
    final duplicateName = provider
        .getAllProductsWithVariants()
        .any((product) =>
            product.id != widget.product?.id &&
            product.name.trim().toLowerCase() == name.toLowerCase());
    if (duplicateName) {
      _message('A product with this name already exists.');
      return;
    }

    if (barcode.isNotEmpty) {
      final duplicateBarcode = provider
          .getAllProductsWithVariants()
          .any((product) =>
              product.id != widget.product?.id &&
              product.barcode?.trim() == barcode);
      if (duplicateBarcode) {
        _message('That barcode is already used by another product.');
        return;
      }
    }

    setState(() => _saving = true);
    final now = DateTime.now();

    if (widget.product != null) {
      final updated = widget.product!.copyWith(
        name: name,
        category: _category,
        unit: _unit,
        barcode: barcode.isEmpty ? null : barcode,
        lastModified: now,
      );
      await provider.upsertProduct(updated);
    } else {
      const uuid = Uuid();
      final id = uuid.v4();
      final stocks = initialStock == 0
          ? <ProductStock>[]
          : [
              ProductStock(
                id: uuid.v4(),
                productId: id,
                quantity: initialStock,
                costPrice: 0,
                retailPrice: 0,
                dateReceived: now,
                lastModified: now,
              ),
            ];

      await provider.upsertProduct(
        Product(
          id: id,
          name: name,
          category: _category,
          isSoldByPack: true,
          isSoldByPiece: false,
          unit: _unit,
          barcode: barcode.isEmpty ? null : barcode,
          createdAt: now,
          lastModified: now,
          stocks: stocks,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    _message(widget.isEditing ? 'Product updated.' : 'Product added.');
  }

  Future<void> _archive() async {
    final product = widget.product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive product?'),
        content: Text(
          '${product.name} will leave the active inventory. You can restore it from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await context.read<ProductProvider>().softDeleteProduct(product.id);
    if (!mounted) return;
    Navigator.pop(context);
    _message('Product archived.');
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
