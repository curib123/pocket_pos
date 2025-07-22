import 'package:flutter/material.dart';
import 'package:retailpos/Helper/AppColor.dart';
import 'package:retailpos/Model/product_stock.dart';
import 'package:retailpos/View/Components/Custom/CustomTextField.dart';
import 'package:retailpos/View/Components/Custom/CustomButton.dart';
import 'package:retailpos/View/Components/Custom/CustomFlatDropdown.dart';
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
  double? _selectedMargin;

  @override
  void initState() {
    super.initState();

    _dateReceived = widget.existingStock?.dateReceived ??
        widget.dateReceived ??
        DateTime.now();

    _qtyController.text = widget.existingStock?.quantity.toString() ?? '';
    _costController.text = widget.existingStock?.costPrice.toString() ?? '';
    _retailController.text =
        widget.existingStock?.retailPrice.toString() ?? '';

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
      productId: widget.productId,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColor.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Update Stock' : 'Add Stock',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
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
                      itemBuilder: (val) =>
                          Text("${(val * 100).toStringAsFixed(0)}%"),
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
                    const SizedBox(height: 20),
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
