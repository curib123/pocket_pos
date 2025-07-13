import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Provider/BatchProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_pos_inventory/Helper/Enums/enum.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/batch_model.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/showImageSourcePicker.dart';

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
  final _retailPrice = TextEditingController();
  final _quantity = TextEditingController();
  final _newBatchQty = TextEditingController();
  final _itemsPerBundle = TextEditingController();

  bool _showNewBatchInput = false;
  List<Batch> _existingBatches = [];

  String? _selectedCategory;
  String? _selectedUnit;
  File? _imageFile;

  double? _selectedProfitPercent;
  final List<double> _profitOptions = List.generate(100, (index) => (index + 1) / 100);

  bool get isEditing => widget.existingProduct != null;
  bool get isBundleUnit => UnitTypeExtension.supportsSubQuantity(_selectedUnit);

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final p = widget.existingProduct!;
      _name.text = p.name;
      _description.text = p.description;
      _costPrice.text = p.costPrice.toString();
      _retailPrice.text = p.retailPrice.toString();
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      if (p.unit == UnitType.pack.name) _itemsPerBundle.text = p.itemsPerBundle.toString();
      if (p.imageUrl.isNotEmpty) _imageFile = File(p.imageUrl);
      _existingBatches = List.from(p.batches);
    } else {
      _selectedCategory = widget.category;
    }

    _setupProfitCalculationListener();
  }

  void _setupProfitCalculationListener() {
    void listener() {
      final cost = double.tryParse(_costPrice.text);
      final qty = double.tryParse(_quantity.text);
      if (cost != null && qty != null && qty > 0 && _selectedProfitPercent != null) {
        final costPerItem = cost / qty;
        final retail = (costPerItem * (1 + _selectedProfitPercent!)).toStringAsFixed(2);
        _retailPrice.text = retail;
      }
    }

    _costPrice.addListener(listener);
    _quantity.addListener(listener);
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
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    Widget Function(T)? itemBuilder,  // optional
    IconData? icon,
    String? helperText,
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
            prefixIcon: icon, // icon inside
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(helperText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

    if (!widget.isRestock && (_selectedCategory == null || _selectedUnit == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Category and Unit')),
      );
      return;
    }

    if (widget.isRestock && !_showNewBatchInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm and enter new batch quantity')),
      );
      return;
    }

    final rawQty = double.tryParse(widget.isRestock ? _newBatchQty.text : _quantity.text) ?? 0;
    final itemsPerBundle = isBundleUnit ? int.tryParse(_itemsPerBundle.text) ?? 1 : 1;
    final bundleQty = rawQty;
    final subQty = bundleQty * itemsPerBundle;

    final newBatch = Batch(
      id: const Uuid().v4(),
      quantity: bundleQty,
      createdAt: DateTime.now(),
      subQuantity: subQty,
    );

    final product = Product(
      id: isEditing ? widget.existingProduct!.id : const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim(),
      costPrice: double.tryParse(_costPrice.text) ?? 0,
      retailPrice: double.tryParse(_retailPrice.text) ?? 0,
      unit: _selectedUnit ?? '',
      category: _selectedCategory ?? '',
      imageUrl: _imageFile?.path ?? '',
      batches: widget.isRestock
          ? [..._existingBatches, newBatch]
          : isEditing
          ? _existingBatches
          : [newBatch],
      lastModified: DateTime.now(),
      deletedAt: null,
      itemsPerBundle: itemsPerBundle,
    );

    if (widget.isRestock) {
      batchProvider.addBatch(product.name, newBatch, itemsPerBundle.toDouble());
    } else if (isEditing) {
      productProvider.updateProduct(product);
    } else {
      productProvider.addProduct(product);
    }

    Navigator.pop(context);
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

                  _buildTextFieldWithIcon(
                    label: 'Cost Price (Total)',
                    controller: _costPrice,
                    keyboardType: TextInputType.number,
                    icon: LucideIcons.dollarSign,
                    helperText: 'Enter the total amount you paid for this stock. Use numbers only.',
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

                  _buildDropdown<double>(
                    hint: 'Select Profit Margin',
                    value: _selectedProfitPercent,
                    items: _profitOptions,
                    onChanged: (val) {
                      setState(() => _selectedProfitPercent = val);
                      final cost = double.tryParse(_costPrice.text);
                      final qty = double.tryParse(_quantity.text);
                      if (cost != null && qty != null && qty > 0 && val != null) {
                        final costPerItem = cost / qty;
                        _retailPrice.text = (costPerItem * (1 + val)).toStringAsFixed(2);
                      }
                    },
                    itemBuilder: (val) => Text('${(val * 100).toInt()}%'),
                    icon: LucideIcons.percent,
                    helperText: 'Choose how much profit you want to make on each item, e.g., 10% means selling 10% more than the cost.',
                  ),

                  _buildTextFieldWithIcon(
                    label: 'Retail Price (Per Item)',
                    controller: _retailPrice,
                    keyboardType: TextInputType.number,
                    icon: LucideIcons.tag,
                    helperText: 'Price you want to sell one item for. This updates automatically based on profit margin.',
                  ),

                  if (isBundleUnit && !isEditing)
                    _buildTextFieldWithIcon(
                      label: 'Items Per Pack',
                      controller: _itemsPerBundle,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '');
                        return (val == null || val <= 0) ? 'Enter a valid number' : null;
                      },
                      icon: LucideIcons.package,
                      helperText: 'How many individual items are inside one pack? Needed for accurate stock count.',
                    ),

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
                    title: Text('Quantity: ${b.quantity}'),
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
