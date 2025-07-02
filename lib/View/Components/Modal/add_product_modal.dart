// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/UnitList.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddProductModal {
  static void show(BuildContext context, {bool isEdit = false, Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: _ModalContent(isEdit: isEdit, product: product),
          ),
        );
      },
    );
  }
}

class _ModalContent extends StatefulWidget {
  final bool isEdit;
  final Product? product;

  const _ModalContent({Key? key, this.isEdit = false, this.product}) : super(key: key);

  @override
  State<_ModalContent> createState() => _ModalContentState();
}

class _ModalContentState extends State<_ModalContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _retailController = TextEditingController();
  final _descController = TextEditingController();
  final _quantityController = TextEditingController();
  final _kiloQuantityController = TextEditingController();

  String? _selectedCategory;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  Product? _selectedProductToRestock;
  int? _selectedBatchIndex;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _costController.text = p.costPrice.toString();
      _retailController.text = p.retailPrice.toString();
      _descController.text = p.description;
      _selectedCategory = p.category;
      if (p.imageUrl.isNotEmpty) _pickedImage = XFile(p.imageUrl);
      if (p.batches.isNotEmpty) {
        _selectedBatchIndex = 0;
        _quantityController.text = p.batches[0].quantity.toString();
        _kiloQuantityController.text = p.batches[0].kiloQuantity.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _retailController.dispose();
    _descController.dispose();
    _quantityController.dispose();
    _kiloQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  void _submit(BuildContext context) async {



    if (!_formKey.currentState!.validate()) return;

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final now = DateTime.now();
      final id = widget.isEdit ? widget.product!.id : const Uuid().v4();

      String savedImagePath = '';
      if (_pickedImage != null) {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/paninda_images');
        if (!await folder.exists()) await folder.create(recursive: true);

        final ext = _pickedImage!.path.split('.').last;
        final path = '${folder.path}/$id.$ext';
        await File(_pickedImage!.path).copy(path);
        savedImagePath = path;
      }

      // 👉 Restock
      if (_selectedProductToRestock != null) {
        final u = _selectedProductToRestock!;
        u.name = _nameController.text.trim();
        u.costPrice = double.tryParse(_costController.text) ?? 0;
        u.retailPrice = double.tryParse(_retailController.text) ?? 0;
        u.description = _descController.text.trim();
        u.category = _selectedCategory ?? "Uncategorized";
        u.imageUrl = savedImagePath.isNotEmpty ? savedImagePath : u.imageUrl;

        final batch = Batch(
          date: now,
          quantity: double.tryParse(_quantityController.text) ?? 0,
          kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
        );
        u.batches.add(batch);

        provider.updateProduct(u.id, u);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product restocked!"), backgroundColor: AppColor.success),
        );
        return;
      }

      // 👉 Update
      if (widget.isEdit && widget.product != null) {
        final u = widget.product!;
        u.name = _nameController.text.trim();
        u.costPrice = double.tryParse(_costController.text) ?? 0;
        u.retailPrice = double.tryParse(_retailController.text) ?? 0;
        u.description = _descController.text.trim();
        u.category = _selectedCategory ?? "Uncategorized";
        u.imageUrl = savedImagePath.isNotEmpty ? savedImagePath : u.imageUrl;

        final batch = Batch(
          date: now,
          quantity: double.tryParse(_quantityController.text) ?? 0,
          kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
        );

        if (_selectedBatchIndex != null && u.batches.length > _selectedBatchIndex!) {
          u.batches[_selectedBatchIndex!] = batch;
        } else {
          u.batches.add(batch);
        }

        provider.updateProduct(u.id, u);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated!"), backgroundColor: AppColor.success),
        );
        return;
      }

      // 👉 Add new
      final product = Product(
        id: id,
        name: _nameController.text.trim(),
        costPrice: double.tryParse(_costController.text) ?? 0,
        retailPrice: double.tryParse(_retailController.text) ?? 0,
        unit:  "Unit",
        description: _descController.text.trim(),
        imageUrl: savedImagePath,
        category: _selectedCategory ?? "Uncategorized",
        batches: [
          Batch(
            date: now,
            quantity: double.tryParse(_quantityController.text) ?? 0,
            kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
          ),
        ],
      );
      provider.addProduct(product);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added!"), backgroundColor: AppColor.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Try again."),
          backgroundColor: AppColor.warning,
        ),
      );
    }
  }

  Widget _batchDropdown() {
    if (widget.isEdit && widget.product != null && widget.product!.batches.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<int>(
          value: _selectedBatchIndex,
          decoration: InputDecoration(
            hintText: "Select Stock Batch to Edit",
            prefixIcon: const Icon(Icons.list),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: InputBorder.none,
          ),
          items: List.generate(widget.product!.batches.length, (i) {
            final b = widget.product!.batches[i];
            return DropdownMenuItem<int>(
              value: i,
              child: Text("Stock Batch ${i + 1} – ${b.date.toLocal()}"),
            );
          }),
          onChanged: (i) {
            if (i != null) {
              setState(() {
                _selectedBatchIndex = i;
                final b = widget.product!.batches[i];
                _quantityController.text = b.quantity.toString();
                _kiloQuantityController.text = b.kiloQuantity.toString();
              });
            }
          },
          validator: (val) => val == null ? 'Please select a batch' : null,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Consumer2<StoreCategoryProvider, ProductProvider>(
            builder: (context, catProv, productProvider, _) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Text(
                    widget.isEdit ? "Edit Product" : "Add New Product",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _batchDropdown(),

                  // 👇 Autocomplete Product Name
                  Autocomplete<Product>(
                    displayStringForOption: (p) => p.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return productProvider.products.where((Product option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      }).take(5);
                    },

                    fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
                      textEditingController.text = _nameController.text;
                      textEditingController.addListener(() {
                        _nameController.text = textEditingController.text;
                      });

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        decoration: InputDecoration(
                          hintText: "Enter Product Name",
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          border: InputBorder.none,
                        ),
                      );
                    },
                    onSelected: (Product selected) {
                      setState(() {
                        _selectedProductToRestock = selected;
                        _nameController.text = selected.name;
                        _costController.text = selected.costPrice.toString();
                        _retailController.text = selected.retailPrice.toString();
                        _descController.text = selected.description;
                        _selectedCategory = selected.category;
                        _pickedImage = selected.imageUrl.isNotEmpty ? XFile(selected.imageUrl) : null;
                        _quantityController.clear();
                        _kiloQuantityController.clear();
                      });
                    },
                  ),

                  if (_selectedProductToRestock != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Previous Stocks Batch", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _selectedProductToRestock!.batches.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text("Date: ${b.date.toLocal()} | Qty: ${b.quantity}, Kg: ${b.kiloQuantity}"),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 10),
                  _modernInput(_costController, "Cost Price", Icons.monetization_on_outlined, type: TextInputType.number),
                  _modernInput(_retailController, "Retail Price", Icons.price_check_outlined, type: TextInputType.number),
                  _modernDropdown("Category", Icons.category_outlined, _selectedCategory, catProv.visibleCategories, (val) => setState(() => _selectedCategory = val)),
                  _modernInput(_descController, "Description", Icons.notes_outlined, maxLines: 2),
                  _imagePickerPreview(),
                  const SizedBox(height: 20),
                  _modernInput(_quantityController, "Quantity (pcs)", Icons.shopping_bag_outlined, type: TextInputType.number),
                  _modernInput(_kiloQuantityController, "Quantity (kilos)", Icons.scale_outlined, type: TextInputType.number),
                  const SizedBox(height: 20),

                  CustomButton(
                    icon: Icons.save,
                    color: AppColor.secondary,
                    label: widget.isEdit ? "Update Product" : (_selectedProductToRestock != null ? "Restock Product" : "Add Product"),
                    onPressed: () {

              if(_quantityController.text.isEmpty ||
                  _kiloQuantityController.text.isEmpty ||
                  _descController.text.isEmpty
              ) {

                _quantityController.text = 0.toString();
                _kiloQuantityController.text = 0.toString();
                _descController.text = "No Description";

              }

              _submit(context);

              } ,
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    icon: Icons.cancel,
                    color: AppColor.error,
                    label: "Cancel",
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _modernInput(TextEditingController c, String hint, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _modernDropdown(String label, IconData icon, String? value, List<String> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: InputBorder.none,
        ),
        items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _imagePickerPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Product Image", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              image: _pickedImage != null
                  ? DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover)
                  : null,
            ),
            child: _pickedImage == null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text("Tap to capture product image", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
                : null,
          ),
        ),
      ],
    );
  }
}
