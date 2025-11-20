import 'package:flutter/material.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/View/Components/Custom/CustomTextField.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:nextpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:uuid/uuid.dart';

class AddOrEditStockDialog extends StatefulWidget {
  final String productId;
  final DateTime? dateReceived;
  final ProductStock? existingStock;
  final bool isSoldByPack;
  final bool isSoldByPiece;
  final int packSize;

  const AddOrEditStockDialog({
    super.key,
    required this.productId,
    this.dateReceived,
    this.existingStock,
    required this.isSoldByPack,
    required this.isSoldByPiece,
    required this.packSize,
  });

  @override
  State<AddOrEditStockDialog> createState() => _AddOrEditStockDialogState();
}

class _AddOrEditStockDialogState extends State<AddOrEditStockDialog> {
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();
  final _retailController = TextEditingController();
  final _costPerPieceController = TextEditingController();
  final _retailPerPieceController = TextEditingController();
  final _piecesPerPackController = TextEditingController();

  late DateTime _dateReceived;
  double? _selectedMargin;
  bool _isSyncing = false;

  int get _packSize => int.tryParse(_piecesPerPackController.text.trim()) ?? 1;

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
    _piecesPerPackController.text = widget.packSize.toString();

    _costPerPieceController.text = _computePerPiece(_costController.text);
    _retailPerPieceController.text = _computePerPiece(_retailController.text);

    _piecesPerPackController.addListener(() {
      _syncCostViceVersa();
      _syncRetailViceVersa();
    });

    _costController.addListener(() {
      _recalculateRetailFromMargin();
      _syncCostViceVersa();
    });

    _retailController.addListener(() {
      _syncRetailViceVersa();
    });

    _costPerPieceController.addListener(() {
      if (!_isSyncing && widget.isSoldByPiece && !widget.isSoldByPack) {
        final val = double.tryParse(_costPerPieceController.text);
        if (val != null) _costController.text = val.toStringAsFixed(2);
      } else if (!_isSyncing && widget.isSoldByPack) {
        final perPiece = double.tryParse(_costPerPieceController.text);
        if (perPiece != null) {
          _isSyncing = true;
          _costController.text = (perPiece * _packSize).toStringAsFixed(2);
          _isSyncing = false;
        }
      }
    });

    _retailPerPieceController.addListener(() {
      if (!_isSyncing && widget.isSoldByPiece && !widget.isSoldByPack) {
        final val = double.tryParse(_retailPerPieceController.text);
        if (val != null) _retailController.text = val.toStringAsFixed(2);
      } else if (!_isSyncing && widget.isSoldByPack) {
        final perPiece = double.tryParse(_retailPerPieceController.text);
        if (perPiece != null) {
          _isSyncing = true;
          _retailController.text = (perPiece * _packSize).toStringAsFixed(2);
          _isSyncing = false;
        }
      }
    });
  }

  String _computePerPiece(String text) {
    final val = double.tryParse(text.trim());
    return (val != null && _packSize > 0)
        ? (val / _packSize).toStringAsFixed(2)
        : '';
  }

  void _recalculateRetailFromMargin() {
    final cost = double.tryParse(_costController.text.trim());
    if (cost != null && _selectedMargin != null) {
      final retail = cost + (cost * _selectedMargin!);
     widget.isSoldByPack ? _retailController.text = retail.toStringAsFixed(2)  :
      _retailPerPieceController.text = retail.toStringAsFixed(2);
    }
  }

  void _syncCostViceVersa() {
    if (_isSyncing || _packSize <= 0) return;
    final cost = double.tryParse(_costController.text.trim());
    if (cost == null) return;
    _isSyncing = true;
    _costPerPieceController.text = (cost / _packSize).toStringAsFixed(2);
    _isSyncing = false;
  }

  void _syncRetailViceVersa() {
    if (_isSyncing || _packSize <= 0) return;
    final retail = double.tryParse(_retailController.text.trim());
    if (retail == null) return;
    _isSyncing = true;
    _retailPerPieceController.text = (retail / _packSize).toStringAsFixed(2);
    _isSyncing = false;
  }

  void _submit() {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    final costPerPack = double.tryParse(_costController.text.trim()) ?? 0.0;
    final retailPerPack = double.tryParse(_retailController.text.trim()) ?? 0.0;

    final costPerPiece = double.tryParse(_costPerPieceController.text.trim()) ?? 0.0;
    final retailPerPiece = double.tryParse(_retailPerPieceController.text.trim()) ?? 0.0;

    // Validation for negative values depending on selling method
    final hasNegativeValues = widget.isSoldByPack
        ? (qty < 0 || costPerPack < 0 || retailPerPack < 0)
        : (qty < 0 || costPerPiece < 0 || retailPerPiece < 0);

    if (hasNegativeValues) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Values must be non-negative")),
      );
      return;
    }

    final newStock = ProductStock(
      id: widget.existingStock?.id ?? const Uuid().v4(),
      productId: widget.productId,
      quantity: qty,
      costPrice: widget.isSoldByPack ? costPerPack : costPerPiece,
      retailPrice: widget.isSoldByPack ? retailPerPack : retailPerPiece,
      dateReceived: _dateReceived,
      lastModified: DateTime.now(),
      deletedAt: null,
    );

    Navigator.pop(context, newStock);
  }


  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStock != null;
    final margins = List.generate(100, (i) => (i + 1) / 100.0);

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
                      helperText:
                      "Total number of ${widget.isSoldByPack ? 'packs' : 'pieces'} received",
                      prefixIcon: const Icon(Icons.layers),
                    ),
                    if (widget.isSoldByPack)
                      CustomTextField(
                        label: "Pieces per Pack",
                        controller: _piecesPerPackController,
                        keyboardType: TextInputType.number,
                        hintText: "e.g. 6",
                        isRequired: true,
                        readOnly: true,
                        helperText:
                        "Used for converting cost/retail per piece",
                        prefixIcon: const Icon(Icons.all_inbox_rounded),
                      ),
                    const SizedBox(height: 12),
                    if (widget.isSoldByPack) ...[
                      CustomTextField(
                        label: "Cost per Pack",
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        hintText: "e.g. 12.50",
                        isRequired: true,
                        helperText: "Buying cost per pack",
                        prefixIcon: const Icon(Icons.price_change_outlined),
                      ),
                      CustomTextField(
                        label: "Cost per Piece",
                        controller: _costPerPieceController,
                        keyboardType: TextInputType.number,
                        hintText: "Auto from pack, or edit to override",
                        isRequired: false,
                        helperText: "Syncs with cost per pack",
                        prefixIcon: const Icon(Icons.money_off_csred_rounded),
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
                        label: "Retail per Pack",
                        controller: _retailController,
                        keyboardType: TextInputType.number,
                        hintText: "e.g. 19.99",
                        isRequired: true,
                        helperText:
                        "Auto-calculated or manual entry",
                        prefixIcon: const Icon(Icons.sell_outlined),
                      ),
                      CustomTextField(
                        label: "Retail per Piece",
                        controller: _retailPerPieceController,
                        keyboardType: TextInputType.number,
                        hintText: "Auto from pack, or edit to override",
                        isRequired: false,
                        helperText: "Syncs with retail per pack",
                        prefixIcon: const Icon(Icons.price_check),
                      ),
                    ] else if (widget.isSoldByPiece) ...[
                      CustomTextField(
                        label: "Cost per Piece",
                        controller: _costPerPieceController,
                        keyboardType: TextInputType.number,
                        hintText: "e.g. 1.99",
                        isRequired: true,
                        helperText: "Buying cost per piece",
                        prefixIcon: const Icon(Icons.price_change_outlined),
                      ),
                      CustomFlatDropdown<double>(
                        hint: "Select profit margin",
                        helperText: _costController.text.isEmpty || _costPerPieceController.text.isNotEmpty
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
                        label: "Retail per Piece",
                        controller: _retailPerPieceController,
                        keyboardType: TextInputType.number,
                        hintText: "e.g. 2.99",
                        isRequired: true,
                        helperText: "Selling price per piece",
                        prefixIcon: const Icon(Icons.sell_outlined),
                      ),
                    ],
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
