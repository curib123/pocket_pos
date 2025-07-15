// ✅ FINALIZED ProductModalForm — ALL CODE INCLUDED

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Helper/Enums/enum.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/batch_model.dart';
import 'package:mobile_pos_inventory/Provider/BatchProvider.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/showImageSourcePicker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ProductModalForm extends StatefulWidget {
  final Product? existingProduct;
  final String category;
  final bool isRestock;

  const ProductModalForm({
    super.key,
    this.existingProduct,
    required this.category,
    this.isRestock = false,
  });

  @override
  State<ProductModalForm> createState() => _ProductModalFormState();
}

class _ProductModalFormState extends State<ProductModalForm> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _costPrice = TextEditingController();
  final _costPricePerItem = TextEditingController();
  final _retailPrice = TextEditingController();
  final _retailPricePerItem = TextEditingController();
  final _quantity = TextEditingController();
  final _newBatchQty = TextEditingController();
  final _itemsPerBundle = TextEditingController();

  File? _imageFile;
  String? _selectedCategory;
  String? _selectedUnit;
  double? _selectedProfitPercent;
  List<Batch> _existingBatches = [];
  bool _showNewBatchInput = false;

  bool get isEditing => widget.existingProduct != null;
  bool get isBundleUnit => UnitTypeExtension.supportsSubQuantity(_selectedUnit);

  final List<double> _profitOptions = List.generate(100, (index) => (index + 1) / 100);

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.existingProduct!;
      _name.text = p.name;
      _description.text = p.description;
      _costPrice.text = p.defaultCost.toStringAsFixed(2);
      _retailPrice.text = p.defaultRetail.toStringAsFixed(2);
      _costPricePerItem.text = p.costPerItem.toStringAsFixed(2);
      _retailPricePerItem.text = p.packItemsRetail.toStringAsFixed(2);
      _itemsPerBundle.text = p.packItems.toStringAsFixed(0);
      _selectedProfitPercent = p.profitMargin;
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      if (p.imageUrl.isNotEmpty) _imageFile = File(p.imageUrl);
      _existingBatches = List.from(p.batches);
    } else {
      _selectedCategory = widget.category;
    }
    _setupProfitCalculationListener();
  }

  void _setupProfitCalculationListener() {
    bool _isUpdating = false;

    void updateRetailFromCost() {
      final costPerItem = double.tryParse(_costPricePerItem.text);
      final qty = double.tryParse(_quantity.text);

      if (costPerItem != null && _selectedProfitPercent != null) {
        final retailPerItem = costPerItem + (costPerItem * _selectedProfitPercent!);
        _retailPricePerItem.text = retailPerItem.toStringAsFixed(2);

        if (qty != null && qty > 0) {
          _retailPrice.text = (retailPerItem * qty).toStringAsFixed(2);
        }
      } else {
        _retailPricePerItem.clear();
        _retailPrice.clear();
      }
    }

    void updateFromCostPrice() {
      if (_isUpdating) return;
      _isUpdating = true;

      final cost = double.tryParse(_costPrice.text);
      final qty = double.tryParse(_quantity.text);

      if ((cost == null || qty == null || qty <= 0)) {
        _costPricePerItem.clear();
        _retailPrice.clear();
        _retailPricePerItem.clear();
        _isUpdating = false;
        return;
      }

      _costPricePerItem.text = (cost / qty).toStringAsFixed(2);
      updateRetailFromCost();
      _isUpdating = false;
    }

    void updateFromCostPerItem() {
      if (_isUpdating) return;
      _isUpdating = true;

      final costPerItem = double.tryParse(_costPricePerItem.text);
      final qty = double.tryParse(_quantity.text);

      if ((costPerItem == null || qty == null || qty <= 0)) {
        _costPrice.clear();
        _retailPrice.clear();
        _retailPricePerItem.clear();
        _isUpdating = false;
        return;
      }

      _costPrice.text = (costPerItem * qty).toStringAsFixed(2);
      updateRetailFromCost();
      _isUpdating = false;
    }

    void updateFromRetailTotal() {
      if (_isUpdating) return;
      _isUpdating = true;

      final retail = double.tryParse(_retailPrice.text);
      final qty = double.tryParse(_quantity.text);

      if (retail != null && qty != null && qty > 0) {
        _retailPricePerItem.text = (retail / qty).toStringAsFixed(2);
      }

      _isUpdating = false;
    }

    void updateFromRetailPerItem() {
      if (_isUpdating) return;
      _isUpdating = true;

      final retailPerItem = double.tryParse(_retailPricePerItem.text);
      final qty = double.tryParse(_quantity.text);

      if (retailPerItem != null && qty != null && qty > 0) {
        _retailPrice.text = (retailPerItem * qty).toStringAsFixed(2);
      }

      _isUpdating = false;
    }

    _costPrice.addListener(updateFromCostPrice);
    _costPricePerItem.addListener(updateFromCostPerItem);
    _retailPrice.addListener(updateFromRetailTotal);
    _retailPricePerItem.addListener(updateFromRetailPerItem);

    _quantity.addListener(() {
      if (_costPrice.text.isNotEmpty) {
        updateFromCostPrice();
      } else if (_costPricePerItem.text.isNotEmpty) {
        updateFromCostPerItem();
      }

      if (_retailPrice.text.isNotEmpty) {
        updateFromRetailTotal();
      } else if (_retailPricePerItem.text.isNotEmpty) {
        updateFromRetailPerItem();
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Widget _buildTextFieldWithIcon({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
    String? helperText,
    bool obscure = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: CustomTextField(
        label: label,
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscure: obscure,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        helperText: helperText,
        readOnly: readOnly,
      ),
    );
  }
  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    Widget Function(T)? itemBuilder,
    IconData? icon,
    String? helperText,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFlatDropdown<T>(
            hint: hint,
            value: value,
            items: items,
            onChanged: onChanged,
            itemBuilder: itemBuilder ?? (val) => Text(val.toString()),
            prefixIcon: icon,
            readOnly: readOnly,
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                helperText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic, // ✅ Italicized helper text
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }


  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Product Image", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CustomButton(
          text: _imageFile == null ? 'Upload Image' : 'Change Image',
          icon: LucideIcons.image,
          isFilled: false,
          onPressed: () => showImageSourcePicker(context: context, onPick: _pickImage),
        ),
        const SizedBox(height: 12),
        _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: 160),
        )
            : Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey[100],
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Image Selected', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleSubmit(ProductProvider productProvider, BatchProvider batchProvider) {
    if (!_formKey.currentState!.validate()) return;

    // Validate required selections when not restocking
    if (!widget.isRestock && (_selectedCategory?.isEmpty ?? true )) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Category and Unit')),
      );
      return;
    }

    // Validate new batch input for restocking
    if (widget.isRestock && (!_showNewBatchInput || _newBatchQty.text.isEmpty || double.tryParse(_newBatchQty.text) == 0)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm and enter new batch quantity')),
      );
      return;
    }

    // Quantity handling
    final rawQty = double.tryParse(widget.isRestock ? _newBatchQty.text : _quantity.text) ?? 0;
    final itemsPerPack = isBundleUnit ? double.tryParse(_itemsPerBundle.text) ?? 1 : 1;
    final packQty = rawQty;
    final subQty = packQty * itemsPerPack;

    // Create new batch
    final newBatch = Batch(
      id: const Uuid().v4(),
      quantity: packQty,
      subQuantity: subQty,
      createdAt: DateTime.now(),
    );

    // Prices
    final defaultCostTotal = double.tryParse(_costPrice.text) ?? 0;
    final defaultCostPerItem = double.tryParse(_costPricePerItem.text) ?? 0;
    final defaultRetailTotal = double.tryParse(_retailPrice.text) ?? 0;
    final defaultRetailPerItem = double.tryParse(_retailPricePerItem.text) ?? 0;
    final packCost = defaultCostPerItem * itemsPerPack;

    // Final product creation
    final product = Product(
      id: isEditing ? widget.existingProduct!.id : const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _imageFile?.path ?? '',
      unit: _selectedUnit ?? '',
      category: _selectedCategory ?? '',
      batches: widget.isRestock
          ? [..._existingBatches, newBatch]
          : isEditing
          ? _existingBatches
          : [newBatch],
      lastModified: DateTime.now(),
      deletedAt: null,
      defaultCost: _selectedUnit == UnitType.pack.label ? packCost : defaultCostTotal,
      defaultRetail: defaultRetailTotal,
      isPack: isBundleUnit,
      packItems: itemsPerPack.toDouble(),
      packItemsCost: defaultCostPerItem,
      packItemsRetail: defaultRetailPerItem,
      profitMargin: _selectedProfitPercent ?? 0,
    );

    // Final action
    if (widget.isRestock) {
      batchProvider.addBatch(product.name, newBatch, itemsPerPack.toDouble());
    } else if (isEditing) {
      productProvider.updateProduct(product);
    } else {
      productProvider.addProduct(product);
    }

    Navigator.pop(context);
  }


  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _costPrice.dispose();
    _costPricePerItem.dispose();
    _retailPrice.dispose();
    _retailPricePerItem.dispose();
    _quantity.dispose();
    _newBatchQty.dispose();
    _itemsPerBundle.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return Consumer3<StoreCategoryProvider, ProductProvider, BatchProvider>(
      builder: (_, storeCategoryProvider, productProvider, batchProvider, __) {
        final unitList = UnitTypeExtension.valuesAsString;

        if (!storeCategoryProvider.visibleCategories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
        if (!unitList.contains(_selectedUnit)) {
          _selectedUnit = null;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEditing
                          ? (widget.isRestock ? Icons.inventory_2_outlined : Icons.edit)
                          : Icons.add_circle_rounded,
                      color: AppColor.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing
                          ? (widget.isRestock ? 'Restock Product' : 'Edit Product')
                          : 'Add Product',
                      style: TextStyle(color: AppColor.primary,fontWeight: FontWeight.bold,fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!widget.isRestock) ...[
                  _buildDropdown<String>(
                    hint: "Select Product Category",
                    value: _selectedCategory,
                    items: storeCategoryProvider.visibleCategories,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    icon: LucideIcons.layers,
                    helperText: 'Choose the category that best fits your product. This helps organize your inventory.',
                  ),
                  _buildDropdown<String>(
                    hint: "Select Product Unit",
                    value: _selectedUnit,
                    items: unitList,
                    onChanged: (val) => setState(() => _selectedUnit = val),
                    icon: LucideIcons.ruler,
                    helperText: 'Pick the unit for measuring your product (e.g., piece, pack).',
                  ),

                  _buildTextFieldWithIcon(
                    label: 'Product Name',
                    controller: _name,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    icon: LucideIcons.box,
                    helperText: 'Enter a clear and descriptive name for the product.',
                  ),

                  _buildTextFieldWithIcon(
                    label: 'Description (Optional)',
                    controller: _description,
                    icon: LucideIcons.info,
                    helperText: 'Add any notes or details about the product (optional).',
                  ),

                  if(!isEditing) ...[
                    _buildTextFieldWithIcon(
                      label: 'Quantity',
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      icon: LucideIcons.layers,
                      helperText: 'Enter how many items or packs you are adding to stock.',
                    ),
                  ],

                    if (isBundleUnit)
                      _buildTextFieldWithIcon(
                        label: 'Items Per Pack',
                        controller: _itemsPerBundle,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final val = int.tryParse(v ?? '');
                          return (val == null || val <= 0) ? 'Enter a valid number' : null;
                        },
                        icon: LucideIcons.package,
                        helperText: 'How many items in one pack',
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pricing Guide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter quantity first. Then enter total or per item cost — the other auto-fills.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildTextFieldWithIcon(
                          label: 'Total Buying Cost ',
                          controller: _costPrice,
                          keyboardType: TextInputType.number,
                          readOnly: _quantity.text.isEmpty,
                          icon: LucideIcons.dollarSign,
                          helperText: 'Total amount spent for the stock.',
                        ),

                        _buildTextFieldWithIcon(
                          label: 'Buying Cost Per ${_selectedUnit == UnitType.pack.label ? UnitType.pack.label : UnitType.pcs.label}',
                          controller: _costPricePerItem,
                          keyboardType: TextInputType.number,
                          readOnly: _quantity.text.isEmpty,
                          icon: LucideIcons.dollarSign,
                          helperText: 'Auto-filled if total cost and quantity are set.',
                        ),

                      ],
                    ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retail Price Guide',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profit margin adds markup to cost. Enter cost, select margin, and prices are auto-generated.',
                        style: TextStyle(fontSize: 10.3, color: Colors.grey),
                      ),


                      const SizedBox(height: 12),

                      _buildDropdown<double>(
                        hint: 'Select Profit Margin',
                        value: _selectedProfitPercent,
                        items: _profitOptions,
                        readOnly: _costPrice.text.trim().isEmpty && _costPricePerItem.text.trim().isEmpty,
                        onChanged: (val) {
                          setState(() => _selectedProfitPercent = val);

                          final costPerItem = double.tryParse(_costPricePerItem.text);
                          final qty = double.tryParse(_quantity.text);

                          if (costPerItem != null && val != null) {
                            final retailPerItem = costPerItem * (1 + val);
                            _retailPricePerItem.text = retailPerItem.toStringAsFixed(2);
                            _retailPrice.text = (qty != null && qty > 0)
                                ? retailPerItem.toStringAsFixed(2)
                                : '';
                          } else {
                            _retailPrice.clear();
                            _retailPricePerItem.clear();
                          }
                        },
                        itemBuilder: (val) => Text('${(val * 100).toInt()}%'),
                        icon: LucideIcons.percent,
                        helperText: 'Enter cost first. Then choose profit % to get price.',
                      ),

                      const SizedBox(height: 6),

                      if (_selectedUnit == UnitType.pack.label) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'You can enter either the total pack price or the per-item price:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        _buildTextFieldWithIcon(
                          label: 'Selling Price (Per Pack)',
                          controller: _retailPrice,
                          keyboardType: TextInputType.number,
                          icon: LucideIcons.tag,
                          helperText: 'Selling price for one full pack. Auto or manual.',
                        ),
                        _buildTextFieldWithIcon(
                          label: 'Selling Price (Per Item)',
                          controller: _retailPricePerItem,
                          keyboardType: TextInputType.number,
                          icon: LucideIcons.tag,
                          helperText: 'Auto-calculated price for 1 item in the pack.',
                        ),
                      ] else ...[
                        _buildTextFieldWithIcon(
                          label: 'Selling Price',
                          controller: _retailPrice,
                          keyboardType: TextInputType.number,
                          icon: LucideIcons.tag,
                          helperText: 'Selling price for 1 item. Auto or manual.',
                        ),
                      ],

                    ],
                  )


                ],

               if(!widget.isRestock)...[
                 const SizedBox(height: 20),
                 _buildImageSection(),

               ],

                if (isEditing) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Existing Batches:', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  ..._existingBatches.map((b) => ListTile(
                    title: Text('Quantity: ${ b.quantity} | ${widget.existingProduct!.unit}'),
                    subtitle: Text('Added: ${DateFormat('MMM d, y').format(b.createdAt.toLocal())}'),
                  )),
                ],
                if (isEditing && widget.isRestock) ...[
                  const SizedBox(height: 12),
                  _showNewBatchInput
                      ? Column(
                    children: [
                      _buildTextFieldWithIcon(
                        label: 'New Stock Quantity',
                        controller: _newBatchQty,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final qty = double.tryParse(v ?? '');
                          return (qty == null || qty <= 0) ? 'Enter a valid quantity' : null;
                        },
                        icon: LucideIcons.layers,
                        helperText: 'Enter quantity for new stock batch',
                      ),

                        _buildTextFieldWithIcon(
                          label: 'Items Per Pack',
                          controller: _itemsPerBundle,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            return (val == null || val <= 0) ? 'Enter a valid number' : null;
                          },
                          icon: LucideIcons.package,
                          helperText: 'How many items in one pack',
                        ),

                    ],
                  )
                      : CustomButton(
                    text: 'Add Batch',
                    icon: Icons.add,
                    isFilled: false,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => CustomConfirmDialog(
                          title: 'Add New Batch',
                          content: 'Do you want to add a new stock batch?',
                          onConfirm: () => setState(() => _showNewBatchInput = true),
                          onCancel: (){},
                        ),
                      );
                      if (confirmed == true) setState(() => _showNewBatchInput = true);
                    },
                  ),
                ],

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Cancel",
                        isFilled: false,
                        icon: Icons.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: widget.isRestock ? "Restock" : isEditing ? "Update" : "Save",
                        icon: Icons.save,
                        onPressed: () => _handleSubmit(productProvider, batchProvider),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
