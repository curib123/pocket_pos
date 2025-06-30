// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:paninda/Model/product_model.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/StoreCategory.dart';
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
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _ModalContent(isEdit: isEdit, product: product),
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

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      try {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        final now = DateTime.now();
        final id = widget.isEdit ? widget.product!.id : const Uuid().v4();

        final product = Product(
          id: id,
          name: _nameController.text.trim(),
          costPrice: double.tryParse(_costController.text) ?? 0,
          retailPrice: double.tryParse(_retailController.text) ?? 0,
          unit: _selectedUnit ?? "Unit",
          description: _descController.text.trim(),
          imageUrl: _pickedImage?.path ?? "",
          category: _selectedCategory ?? "Uncategorized",
          batches: [
            Batch(
              date: now,
              quantity: double.tryParse(_quantityController.text) ?? 0,
              kiloQuantity: double.tryParse(_kiloQuantityController.text) ?? 0,
            )
          ],
        );

        widget.isEdit ? provider.updateProduct(product.id, product) : provider.addProduct(product);

        Navigator.pop(context);
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
          child: Column(
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
              _modernInput(_nameController, "Product Name", Icons.inventory_2_outlined),
              _modernInput(_costController, "Cost Price (how much you paid)", Icons.monetization_on_outlined, type: TextInputType.number),
              _modernInput(_retailController, "Retail Price (how much you sell it)", Icons.price_check_outlined, type: TextInputType.number),
              _modernDropdown("Unit (e.g. sack, bag, pc)", Icons.straighten_outlined, _selectedUnit, UnitList.all, (val) => setState(() => _selectedUnit = val)),
              _modernDropdown("Category", Icons.category_outlined, _selectedCategory, StoreCategory.all, (val) => setState(() => _selectedCategory = val)),
              _modernInput(_descController, "Description", Icons.notes_outlined, maxLines: 2),
              const SizedBox(height: 15),
              _imagePickerPreview(),
              const SizedBox(height: 24),
              _modernInput(_quantityController, "Total Quantity (Pieces)", Icons.shopping_bag_outlined, type: TextInputType.number),
              _modernInput(_kiloQuantityController, "Total Kilos (Optional/Enter 0 if not applicable)", Icons.scale_outlined, type: TextInputType.number),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    CustomButton(
                      icon: Icons.add_circle_rounded,
                      color: AppColor.secondary,
                      label: widget.isEdit ? "Update Product" : "Add Product",
                      onPressed: () => _submit(context),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      icon: Icons.cancel_rounded,
                      color: AppColor.error, // Make sure this exists and is red-themed
                      label: "Cancel Product",
                      onPressed: () => Navigator.pop(context),
                    )

                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernInput(TextEditingController controller, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
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
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
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
        Text("Product Image", style: TextStyle(fontWeight: FontWeight.w600, color: AppColor.textSecondary)),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade600),
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
