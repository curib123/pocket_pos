import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  bool _showNewBatchInput = false;
  List<Batch> _existingBatches = [];

  String? _selectedCategory;
  String? _selectedUnit;
  File? _imageFile;

  bool get isEditing => widget.existingProduct != null;

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
      if (p.imageUrl.isNotEmpty) _imageFile = File(p.imageUrl);
      _existingBatches = List.from(p.batches);
    } else {
      _selectedCategory = widget.category;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomFlatDropdown<T>(
          hint: hint,
          value: value,
          items: items,
          onChanged: onChanged,
          itemBuilder: (val) => Text(val.toString()),
        ),
        const SizedBox(height: 12),
      ],
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
          onPressed: () {
            showImageSourcePicker(context: context, onPick: _pickImage);
          },
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

  void _handleSubmit(ProductProvider provider) {
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

    final newBatch = Batch(
      id: const Uuid().v4(),
      quantity: double.tryParse(widget.isRestock ? _newBatchQty.text : _quantity.text) ?? 0,
      createdAt: DateTime.now(),
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
          ? [..._existingBatches, newBatch] // ✅ add new batch when restocking
          : isEditing
          ? _existingBatches // ✅ keep old batches when editing
          : [newBatch], // ✅ only use new batch when adding new product
      lastModified: DateTime.now(),
      deletedAt: null,
    );

    if (widget.isRestock) {
      provider.addBatchByProductName(product.name, newBatch);
      Navigator.pop(context);
    } else if (isEditing) {
      provider.updateProduct(product);
    } else {
      provider.addProduct(product);
    }

  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<StoreCategoryProvider, ProductProvider>(
      builder: (_, storeCategoryProvider, productProvider, __) {
        final unitList = UnitTypeExtension.valuesAsString;

        // Prevents errors if preselected values are not in dropdown list
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
                          : Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing
                          ? (widget.isRestock ? 'Restock Product' : 'Edit Product')
                          : 'Add Product',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!widget.isRestock) ...[
                  _buildDropdown<String>(
                    hint: "Select Category",
                    value: _selectedCategory,
                    items: storeCategoryProvider.visibleCategories,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  _buildDropdown<String>(
                    hint: "Select Unit",
                    value: _selectedUnit,
                    items: unitList,
                    onChanged: (val) => setState(() => _selectedUnit = val),
                  ),
                  CustomTextField(label: 'Product Name', controller: _name, validator: (v) => v!.isEmpty ? 'Required' : null),
                  CustomTextField(label: 'Description', controller: _description),
                  CustomTextField(label: 'Cost Price', controller: _costPrice, keyboardType: TextInputType.number),
                  CustomTextField(label: 'Retail Price', controller: _retailPrice, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
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
                      ? CustomTextField(
                    label: 'New Batch Quantity',
                    controller: _newBatchQty,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final qty = double.tryParse(v ?? '');
                      return (qty == null || qty <= 0) ? 'Enter a valid quantity' : null;
                    },
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
                          onConfirm: () {
                            setState(() => _showNewBatchInput = true);

                          },
                          onCancel: () {

                          },
                        ),
                      );
                      if (confirmed == true) setState(() => _showNewBatchInput = true);
                    },
                  ),
                ],

                if (!isEditing && !widget.isRestock)
                  CustomTextField(
                    label: 'Stock Qty',
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final qty = double.tryParse(v ?? '');
                      return (qty == null || qty <= 0) ? 'Enter a valid stock quantity' : null;
                    },
                  ),

                const SizedBox(height: 20),
                if (!widget.isRestock) ...[
                  _buildImageSection(),
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
                        onPressed: () => _handleSubmit(productProvider),
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
