import 'package:flutter/material.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/StoreCategoryProvider.dart';
import 'package:nextpos/View/Screen/Sub/BarcodeScannerScreen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SimpleProductForm extends StatefulWidget {
  final Product? existingProduct;

  const SimpleProductForm({super.key, this.existingProduct});

  @override
  State<SimpleProductForm> createState() => _SimpleProductFormState();
}

class _SimpleProductFormState extends State<SimpleProductForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late String _unit;
  String? _category;
  bool _saving = false;

  static const _units = <String>[
    'pcs',
    'pack',
    'sachet',
    'bottle',
    'can',
    'box',
    'kg',
    'g',
    'liter',
    'ml',
  ];

  @override
  void initState() {
    super.initState();
    final product = widget.existingProduct;
    _nameController = TextEditingController(text: product?.name ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _unit = product?.unit?.isNotEmpty == true ? product!.unit! : 'pcs';
    _category = product?.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<StoreCategoryProvider>().visibleCategories;
    final categoryValue =
        _category != null && categories.contains(_category) ? _category : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          16,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.existingProduct == null ? 'Add Product' : 'Edit Product',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stock quantity is managed separately through Stock In, Stock Out, and Adjustment.',
                style: TextStyle(color: Colors.black54, height: 1.35),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  hintText: 'Example: Sardines 155g',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _units.contains(_unit) ? _unit : 'pcs',
                decoration: const InputDecoration(
                  labelText: 'Tracking unit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: _units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _unit = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    tooltip: 'Scan barcode',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save Product'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );
    if (value != null && mounted) {
      _barcodeController.text = value;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final barcode = _barcodeController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required.')),
      );
      return;
    }

    final provider = context.read<ProductProvider>();
    final existing = widget.existingProduct;

    if (existing == null && provider.productExistsByName(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A product with this name already exists.')),
      );
      return;
    }

    if (barcode.isNotEmpty &&
        existing?.barcode != barcode &&
        provider.barcodeExists(barcode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This barcode is already used by another product.')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();

    final product = existing == null
        ? Product(
            id: const Uuid().v4(),
            name: name,
            category: _category,
            isSoldByPack: false,
            isSoldByPiece: true,
            unit: _unit,
            barcode: barcode.isEmpty ? null : barcode,
            createdAt: now,
            lastModified: now,
            stocks: const [],
            logs: const [],
          )
        : existing.copyWith(
            name: name,
            category: _category,
            unit: _unit,
            barcode: barcode,
            lastModified: now,
          );

    await provider.upsertProduct(product);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }
}
