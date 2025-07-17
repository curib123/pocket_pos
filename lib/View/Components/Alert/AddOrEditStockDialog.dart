import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Model/product_stock.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:uuid/uuid.dart';

class AddOrEditStockDialog extends StatefulWidget {
  final String productId;
  final DateTime? dateReceived;
  final ProductStock? existingStock;
  final bool isSoldByPack;
  final bool isSoldByPiece;

  const AddOrEditStockDialog({
    super.key,
    required this.productId,
    this.dateReceived,
    this.existingStock,
    required this.isSoldByPack,
    required this.isSoldByPiece,
  });

  @override
  State<AddOrEditStockDialog> createState() => _AddOrEditStockDialogState();
}

class _AddOrEditStockDialogState extends State<AddOrEditStockDialog> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _retailController = TextEditingController();

  late DateTime _dateReceived;
  double? _selectedMargin; // decimal: 0.1 = 10%

  @override
  void initState() {
    super.initState();

    _dateReceived = widget.existingStock?.dateReceived ?? widget.dateReceived ?? DateTime.now();

    _qtyController.text = widget.existingStock?.quantity.toString() ?? '';
    _costController.text = widget.existingStock?.costPrice.toString() ?? '';
    _retailController.text = widget.existingStock?.retailPrice.toString() ?? '';

    _costController.addListener(() {
      setState(() {
        _recalculateRetailFromMargin();
      });
    });
  }

  void _recalculateRetailFromMargin() {
    final cost = double.tryParse(_costController.text.trim());
    if (cost != null && _selectedMargin != null) {
      final retail = cost + (cost * _selectedMargin!);
      _retailController.text = retail.toStringAsFixed(2);
    }
  }



  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;
    final retail = double.tryParse(_retailController.text.trim()) ?? 0.0;

    if (qty < 0 || cost < 0 || retail < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Values must be non-negative")),
      );
      return;
    }

    final newStock = ProductStock(
      id: widget.existingStock?.id ?? const Uuid().v4(),
      productId: widget.productId, // still read-only and passed internally
      quantity: qty,
      costPrice: cost,
      retailPrice: retail,
      dateReceived: _dateReceived,
      lastModified: DateTime.now(),
      deletedAt: null,
    );

    Navigator.pop(context, newStock);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStock != null;
    final unitType = widget.isSoldByPack
        ? 'pack'
        : widget.isSoldByPiece
        ? 'piece'
        : 'unit';

    final margins = List.generate(100, (i) => (i + 1) / 100.0); // 1% to 100%

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Update Stock' : 'Add Stock',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            CustomTextField(
              label: "Quantity",
              controller: _qtyController,
              keyboardType: TextInputType.number,
              hintText: "e.g. 25",
              isRequired: true,
              helperText: "Total number of ${unitType}s received",
              prefixIcon: const Icon(Icons.layers),
            ),
            CustomTextField(
              label: "Cost Price",
              controller: _costController,
              keyboardType: TextInputType.number,
              hintText: "e.g. 12.50",
              isRequired: true,
              helperText: "Buying cost per $unitType",
              prefixIcon: const Icon(Icons.price_change_outlined),
            ),
            CustomFlatDropdown<double>(
              hint: "Select profit margin",
              helperText: _costController.text.isEmpty
                  ? "Retail = Cost + (Cost × Margin)"
                  : "Enter cost to enable margin suggestions",
              value: _selectedMargin,
              readOnly: _costController.text.isEmpty,
              items: margins,
              onChanged: (val) {
                setState(() {
                  _selectedMargin = val;
                  _recalculateRetailFromMargin();
                });
              },
              itemBuilder: (val) => Text("${(val * 100).toStringAsFixed(0)}%"),
              prefixIcon: Icons.percent_rounded,
            ),
            CustomTextField(
              label: "Retail Price",
              controller: _retailController,
              keyboardType: TextInputType.number,
              hintText: "e.g. 19.99",
              isRequired: true,
              helperText:
              "Auto-calculated if cost and profit margin is set. Otherwise, type your best guess 😉",
              prefixIcon: const Icon(Icons.sell_outlined),
              readOnly: _costController.text.isEmpty,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: "Cancel",
                isFilled: false,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: isEditing ? "Update" : "Add",
                icon: Icons.save,
                onPressed: _submit,
              ),
            ),
          ],
        )
      ],
    );
  }
}
