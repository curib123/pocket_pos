import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/StoreCategoryProvider.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  late final TextEditingController _reorderLevelController;
  final _initialStockController = TextEditingController(text: '0');

  String? _category;
  String _unit = 'pcs';
  String? _imagePath;
  bool _imageRemoved = false;
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
    _reorderLevelController = TextEditingController(
      text: (product?.reorderLevel ?? 5).toString(),
    );
    _category = product?.category;
    _imagePath = product?.imagePath?.trim().isNotEmpty == true
        ? product!.imagePath
        : null;

    final existingUnit = product?.unit?.trim();
    if (existingUnit != null && existingUnit.isNotEmpty) {
      _unit = existingUnit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _reorderLevelController.dispose();
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
    final hasImage = !_imageRemoved &&
        _imagePath != null &&
        _imagePath!.isNotEmpty &&
        File(_imagePath!).existsSync();

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
                  ? 'Keep the details clear so stock checks stay fast.'
                  : 'Add the basics now. Photo and starting stock are optional.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppBrand.mutedOf(context),
                  ),
            ),
            const SizedBox(height: 20),
            _PhotoPicker(
              imagePath: hasImage ? _imagePath : null,
              enabled: !_saving,
              onPick: _choosePhoto,
              onRemove: hasImage
                  ? () => setState(() {
                        _imagePath = null;
                        _imageRemoved = true;
                      })
                  : null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_saving,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'e.g. Coca-Cola 1.5L',
              ),
            ),
            const SizedBox(height: 12),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Choose a category',
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
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _category = value),
              ),
            if (categories.isNotEmpty) const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _units.contains(_unit) ? _unit : 'pcs',
              decoration: const InputDecoration(
                labelText: 'Stock unit',
                hintText: 'e.g. pcs, pack, bottle',
              ),
              items: _units
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _unit = value ?? 'pcs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              enabled: !_saving,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Barcode (optional)',
                hintText: 'e.g. 4801234567890',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reorderLevelController,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reorder level',
                hintText: 'e.g. 5',
                helperText:
                    'At or below this quantity, the product is marked low stock.',
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
                  hintText: 'e.g. 24',
                  helperText: 'Leave at 0 and use Stock In later if preferred.',
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
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    try {
      final root = await getApplicationDocumentsDirectory();
      final directory = Directory(p.join(root.path, 'product_images'));
      await directory.create(recursive: true);

      final extension = p.extension(picked.path).isEmpty
          ? '.jpg'
          : p.extension(picked.path).toLowerCase();
      final fileName =
          'product-${widget.product?.id ?? 'new'}-${DateTime.now().microsecondsSinceEpoch}$extension';
      final saved = await File(picked.path).copy(
        p.join(directory.path, fileName),
      );

      if (!mounted) return;
      setState(() {
        _imagePath = saved.path;
        _imageRemoved = false;
      });
    } catch (_) {
      _message('Could not save that photo. Please try another image.');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    final initialStock = int.tryParse(_initialStockController.text.trim()) ?? 0;
    final reorderLevel =
        int.tryParse(_reorderLevelController.text.trim());

    if (name.isEmpty) {
      _message('Enter a product name.');
      return;
    }
    if (initialStock < 0) {
      _message('Initial stock cannot be negative.');
      return;
    }
    if (reorderLevel == null || reorderLevel < 0) {
      _message('Enter a valid reorder level of 0 or more.');
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
        imagePath: _imageRemoved ? '' : _imagePath,
        reorderLevel: reorderLevel,
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
      final logs = initialStock == 0
          ? <StockLog>[]
          : [
              StockLog(
                id: uuid.v4(),
                productId: id,
                quantity: initialStock,
                isPiece: false,
                reason: StockLogReason.added,
                remarks: 'Initial stock • 0 → $initialStock',
                dateLogged: now,
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
          imagePath: _imagePath,
          reorderLevel: reorderLevel,
          barcode: barcode.isEmpty ? null : barcode,
          createdAt: now,
          lastModified: now,
          stocks: stocks,
          logs: logs,
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

class _PhotoPicker extends StatelessWidget {
  final String? imagePath;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  const _PhotoPicker({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppBrand.surfaceOf(context),
        border: Border.all(color: AppBrand.borderOf(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: hasImage
                ? Image.file(
                    File(imagePath!),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppBrand.primarySoftOf(context),
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppBrand.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product photo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasImage ? 'Photo added' : 'Optional',
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
