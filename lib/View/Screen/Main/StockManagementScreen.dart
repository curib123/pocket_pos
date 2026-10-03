import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:provider/provider.dart';

enum StockMovementMode { stockIn, stockOut, adjustment }

extension StockMovementModeLabel on StockMovementMode {
  String get label {
    switch (this) {
      case StockMovementMode.stockIn:
        return 'Stock In';
      case StockMovementMode.stockOut:
        return 'Stock Out';
      case StockMovementMode.adjustment:
        return 'Adjustment';
    }
  }

  IconData get icon {
    switch (this) {
      case StockMovementMode.stockIn:
        return LucideIcons.packagePlus;
      case StockMovementMode.stockOut:
        return LucideIcons.packageMinus;
      case StockMovementMode.adjustment:
        return LucideIcons.slidersHorizontal;
    }
  }
}

class StockManagementScreen extends StatefulWidget {
  final StockMovementMode initialMode;
  final String? initialProductId;

  const StockManagementScreen({
    super.key,
    this.initialMode = StockMovementMode.stockIn,
    this.initialProductId,
  });

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  late StockMovementMode _mode;
  String? _productId;
  final _quantityController = TextEditingController();
  final _actualStockController = TextEditingController();
  final _notesController = TextEditingController();
  String _stockOutReason = 'Sold / released';
  bool _submitting = false;

  static const _stockOutReasons = <String>[
    'Sold / released',
    'Damaged',
    'Expired',
    'Personal / store use',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _productId = widget.initialProductId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _actualStockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().getAllProductsWithVariants();
    final selected = _findProduct(products, _productId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Stock'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildGuide(),
            const SizedBox(height: 16),
            _buildProductCard(products, selected),
            const SizedBox(height: 16),
            if (_mode == StockMovementMode.adjustment)
              _buildAdjustmentFields(selected)
            else
              _buildQuantityFields(selected),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting || selected == null ? null : () => _submit(selected),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_mode.icon),
              label: Text(_submitting ? 'Saving…' : 'Save ' + _mode.label),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return SegmentedButton<StockMovementMode>(
      segments: StockMovementMode.values
          .map(
            (mode) => ButtonSegment(
              value: mode,
              label: Text(mode.label),
              icon: Icon(mode.icon, size: 18),
            ),
          )
          .toList(),
      selected: {_mode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        setState(() {
          _mode = selection.first;
          _quantityController.clear();
          _actualStockController.clear();
          _notesController.clear();
        });
      },
    );
  }

  Widget _buildGuide() {
    final String title;
    final String text;
    switch (_mode) {
      case StockMovementMode.stockIn:
        title = 'Receive inventory';
        text = 'Use this only when new items arrive. Current stock increases by the quantity entered.';
        break;
      case StockMovementMode.stockOut:
        title = 'Release inventory';
        text = 'Use this for sold, damaged, expired, or store-used items. Stock can never go below zero.';
        break;
      case StockMovementMode.adjustment:
        title = 'Reconcile physical count';
        text = 'Count the actual items on the shelf, then enter that count. The app records the signed difference automatically.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_mode.icon, color: AppColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.black54, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(List<Product> products, Product? selected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selected?.id,
            isExpanded: true,
            hint: const Text('Select product'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.search),
            ),
            items: products
                .map(
                  (product) => DropdownMenuItem(
                    value: product.id,
                    child: Text(
                      product.name +
                          '  •  ' +
                          product.totalQuantity.toString() +
                          ' ' +
                          (product.unit ?? 'unit'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _productId = value),
          ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('System stock', style: TextStyle(color: Colors.black54)),
                const Spacer(),
                Text(
                  selected.totalQuantity.toString() + ' ' + (selected.unit ?? 'unit'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityFields(Product? selected) {
    return Column(
      children: [
        TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _mode == StockMovementMode.stockIn
                ? 'Quantity received'
                : 'Quantity to remove',
            hintText: 'Enter whole number',
            prefixIcon: Icon(_mode.icon),
            border: const OutlineInputBorder(),
            suffixText: selected?.unit ?? 'unit',
          ),
        ),
        if (_mode == StockMovementMode.stockOut) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stockOutReason,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
              prefixIcon: Icon(LucideIcons.clipboardList),
            ),
            items: _stockOutReasons
                .map((reason) => DropdownMenuItem(value: reason, child: Text(reason)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _stockOutReason = value);
            },
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Example: delivery, end-of-day release, damaged sachets',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_note_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentFields(Product? selected) {
    final systemStock = selected?.totalQuantity ?? 0;
    final actual = int.tryParse(_actualStockController.text.trim());
    final difference = actual == null ? null : actual - systemStock;

    return Column(
      children: [
        TextField(
          controller: _actualStockController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Actual physical stock',
            hintText: 'Count what is really on hand',
            prefixIcon: const Icon(LucideIcons.clipboardCheck),
            border: const OutlineInputBorder(),
            suffixText: selected?.unit ?? 'unit',
          ),
        ),
        if (difference != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Text('Difference'),
                const Spacer(),
                Text(
                  (difference > 0 ? '+' : '') + difference.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Reason for adjustment',
            hintText: 'Required, e.g. physical count correction',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
          ),
        ),
      ],
    );
  }

  Product? _findProduct(List<Product> products, String? id) {
    if (id == null) return null;
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> _submit(Product product) async {
    final provider = context.read<ProductStockProvider>();
    final notes = _notesController.text.trim();

    setState(() => _submitting = true);
    StockOperationResult result;

    try {
      switch (_mode) {
        case StockMovementMode.stockIn:
          final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
          result = await provider.stockIn(
            productId: product.id,
            quantity: qty,
            remarks: notes,
          );
          break;
        case StockMovementMode.stockOut:
          final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
          final reason = notes.isEmpty
              ? _stockOutReason
              : _stockOutReason + ' • ' + notes;
          result = await provider.stockOut(
            productId: product.id,
            quantity: qty,
            remarks: reason,
          );
          break;
        case StockMovementMode.adjustment:
          final actual = int.tryParse(_actualStockController.text.trim()) ?? -1;
          result = await provider.adjustStock(
            productId: product.id,
            actualStock: actual,
            reason: notes,
          );
          break;
      }
    } catch (error) {
      result = StockOperationResult.failure(error.toString());
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      _quantityController.clear();
      _actualStockController.clear();
      _notesController.clear();
      setState(() {});
    }
  }
}
