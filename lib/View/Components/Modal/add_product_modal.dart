// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:paninda/Model/product_model.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/UnitList.dart';

class AddProductModal {
  static void show(BuildContext context, {bool isEdit = false, Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
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

  const _ModalContent({super.key, this.isEdit = false, this.product});

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
  String? _selectedUnit;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  Product? _selectedProductToRestock;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _costController.text = p.costPrice.toString();
      _retailController.text = p.retailPrice.toString();
      _descController.text = p.description;
      _quantityController.text = p.batches.first.quantity.toString();
      _kiloQuantityController.text = p.batches.first.kiloQuantity.toString();
      _selectedUnit = p.unit;
      _selectedCategory = p.category;
      if (p.imageUrl.isNotEmpty) _pickedImage = XFile(p.imageUrl);
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
    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        final now = DateTime.now();
        final id = widget.isEdit ? widget.product!.id : const Uuid().v4();

        String savedImagePath = '';
        if (_pickedImage != null) {
          final directory = await getApplicationDocumentsDirectory();
          final folder = Directory('${directory.path}/paninda_images');
          if (!await folder.exists()) await folder.create(recursive: true);

          final ext = _pickedImage!.path.split('.').last;
          final savedPath = '${folder.path}/$id.$ext';
          await File(_pickedImage!.path).copy(savedPath);
          savedImagePath = savedPath;
        }

        // ✅ Restock Fix
        if (_selectedProductToRestock != null) {
          final updatedProduct = _selectedProductToRestock!;

          updatedProduct.name = _nameController.text.trim();
          updatedProduct.costPrice = double.tryParse(_costController.text) ?? 0;
          updatedProduct.retailPrice = double.tryParse(_retailController.text) ?? 0;
          updatedProduct.unit = _selectedUnit ?? "Unit";
          updatedProduct.description = _descController.text.trim();
          updatedProduct.category = _selectedCategory ?? "Uncategorized";
          updatedProduct.imageUrl = savedImagePath.isNotEmpty
              ? savedImagePath
              : updatedProduct.imageUrl;

          final newBatch = Batch(
            date: now,
            quantity: double.tryParse(_quantityController.text) ?? 0,
            kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
          );
          updatedProduct.batches.add(newBatch);

          provider.updateProduct(updatedProduct.id, updatedProduct);

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product restocked!"), backgroundColor: AppColor.success),
          );
          return;
        }

        // ✅ Add or Edit Product
        final product = Product(
          id: id,
          name: _nameController.text.trim(),
          costPrice: double.tryParse(_costController.text) ?? 0,
          retailPrice: double.tryParse(_retailController.text) ?? 0,
          unit: _selectedUnit ?? "Unit",
          description: _descController.text.trim(),
          imageUrl: savedImagePath.isNotEmpty ? savedImagePath : widget.product?.imageUrl ?? "",
          category: _selectedCategory ?? "Uncategorized",
          batches: [
            Batch(
              date: now,
              quantity: double.tryParse(_quantityController.text) ?? 0,
              kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
            )
          ],
        );

        widget.isEdit
            ? provider.updateProduct(product.id, product)
            : provider.addProduct(product);

        Navigator.pop(context);
        print("Submitted Product: ${product.name}, ${product.costPrice}, ${product.retailPrice}");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? "Product updated!" : "Product added!"),
            backgroundColor: AppColor.success,
          ),
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
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Consumer<StoreCategoryProvider>(
            builder: (context, storeCategoryProvider, _) {
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
                  const SizedBox(height: 24),
                  Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      final allProducts = productProvider.products;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Autocomplete<Product>(
                          displayStringForOption: (p) => p.name,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return allProducts.where((Product option) {
                              return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },

                          // ✅ FIX: Use your _nameController directly
                          fieldViewBuilder: (context, textEditingController, focusNode, onEditingComplete) {
                            textEditingController.text = _nameController.text;

                            // ✅ Listen to changes typed by the user
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
                              _selectedUnit = selected.unit;
                              _pickedImage = selected.imageUrl.isNotEmpty ? XFile(selected.imageUrl) : null;
                              _quantityController.text = '';
                              _kiloQuantityController.text = '';
                            });
                          },
                        ),
                      );
                    },
                  ),


                  if (_selectedProductToRestock != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text("Previous Batches", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
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

                  _modernInput(_costController, "Cost Price", Icons.monetization_on_outlined, type: TextInputType.number),
                  _modernInput(_retailController, "Retail Price", Icons.price_check_outlined, type: TextInputType.number),
                  _modernDropdown("Unit", Icons.straighten_outlined, _selectedUnit, UnitList.all, (val) => setState(() => _selectedUnit = val)),
                  _modernDropdown("Category", Icons.category_outlined, _selectedCategory, storeCategoryProvider.visibleCategories, (val) => setState(() => _selectedCategory = val)),
                  _modernInput(_descController, "Description", Icons.notes_outlined, maxLines: 2),
                  _imagePickerPreview(),
                  const SizedBox(height: 20),
                  _modernInput(_quantityController, "Quantity (pcs)", Icons.shopping_bag_outlined, type: TextInputType.number),
                  _modernInput(_kiloQuantityController, "Quantity (kilos)", Icons.scale_outlined, type: TextInputType.number),
                  const SizedBox(height: 20),

                  CustomButton(
                    icon: Icons.save,
                    color: AppColor.secondary,
                    label: widget.isEdit ? "Update Product" : _selectedProductToRestock != null ? "Restock Product" : "Add Product",
                    onPressed: () => _submit(context),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    icon: Icons.cancel,
                    color: AppColor.error,
                    label: "Cancel",
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _modernInput(TextEditingController controller, String hint, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text("Tap to capture product image", style: TextStyle(color: Colors.grey.shade600)),
            ]))
                : null,
          ),
        ),
      ],
    );
  }
}