import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  final _remarksController = TextEditingController();
  String? _selectedProductId;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProduct?.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products =
        context.watch<ProductProvider>().getAllProductsWithVariants();
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
                    color: AppBrand.primarySoftOf(context),
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
                              color: AppBrand.mutedOf(context),
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
                  color: AppBrand.primaryFaintOf(context),
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
                            color: AppBrand.mutedOf(context),
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
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: widget.type == StockMovementType.adjustment
                    ? 'Reason'
                    : 'Note (optional)',
                hintText: widget.type == StockMovementType.adjustment
                    ? 'e.g. Physical count correction'
                    : 'e.g. Delivery from supplier',
              ),
            ),
            const SizedBox(height: 12),
            _MovementPhotoPicker(
              imagePath: _imagePath,
              enabled: !_saving,
              onPick: _choosePhoto,
              onRemove: _imagePath == null
                  ? null
                  : () => setState(() => _imagePath = null),
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
                      color: AppBrand.mutedOf(context),
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

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    try {
      final root = await getApplicationDocumentsDirectory();
      final directory = Directory(p.join(root.path, 'activity_images'));
      await directory.create(recursive: true);
      final extension = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path).toLowerCase();
      final fileName =
          'activity-${DateTime.now().microsecondsSinceEpoch}$extension';
      final saved = await File(picked.path).copy(
        p.join(directory.path, fileName),
      );
      if (!mounted) return;
      setState(() => _imagePath = saved.path);
    } catch (_) {
      _showMessage('Could not save that photo. Please try another image.');
    }
  }

  Future<void> _submit() async {
    final id = _selectedProductId;
    final quantity = int.tryParse(_quantityController.text.trim());
    final note = _remarksController.text.trim();

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
          remarks: note,
          imagePath: _imagePath,
        ),
      StockMovementType.stockOut => await provider.stockOut(
          productId: id,
          quantity: quantity,
          remarks: note,
          imagePath: _imagePath,
        ),
      StockMovementType.adjustment => await provider.adjustStock(
          productId: id,
          actualStock: quantity,
          reason: note.isEmpty ? 'Physical count correction' : note,
          imagePath: _imagePath,
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

class _MovementPhotoPicker extends StatelessWidget {
  final String? imagePath;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _MovementPhotoPicker({
    required this.imagePath,
    required this.enabled,
    required this.onPick,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppBrand.surfaceOf(context),
        border: Border.all(color: AppBrand.borderOf(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.file(
                    File(imagePath!),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 52,
                    height: 52,
                    color: AppBrand.primarySoftOf(context),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppBrand.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasImage ? 'Photo attached' : 'Optional proof or reference',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppBrand.mutedOf(context),
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? onPick : null,
            child: Text(hasImage ? 'Change' : 'Add'),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove photo',
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
