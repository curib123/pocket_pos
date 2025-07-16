import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomSearchField.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';

class AddProductModal extends StatefulWidget {
  const AddProductModal({super.key});

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _piecesPerPackController = TextEditingController();
  String? _selectedUnit;
  bool _isSoldByPack = false;
  bool _isSoldByPiece = false;
  File? _selectedImage;
  final List<String> _units = ['pcs', 'ml', 'kg', 'pack', 'bottle'];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture from Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitProduct() {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      unit: _selectedUnit ?? 'pcs',
      piecesPerPack: int.tryParse(_piecesPerPackController.text.trim()) ?? 1,
      isSoldByPack: _isSoldByPack,
      isSoldByPiece: _isSoldByPiece,
      imagePath: _selectedImage?.path ?? '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      deletedAt: null,
      stocks: [],
      looseStock: null,
      logs: [],
    );

    final jsonData = JsonEncoder.withIndent('  ').convert(product.toMap());
    debugPrint("📦 New Product Created:\n$jsonData");

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Product Name',
                hintText: 'Enter product name',
                helperText: 'This will appear in listings and receipts',
                controller: _nameController,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Category',
                hintText: 'Enter category (e.g. Cigarettes)',
                helperText: 'Group similar items together',
                controller: _categoryController,
              ),
              const SizedBox(height: 10),
              CustomFlatDropdown<String>(
                label: 'Unit',
                hint: 'Choose measurement unit',
                helperText: 'e.g. pcs, ml, kg',
                value: _selectedUnit,
                items: _units,
                onChanged: (val) => setState(() => _selectedUnit = val),
                itemBuilder: (unit) => Text(unit),
                prefixIcon: Icons.scale,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Pieces per Pack',
                hintText: 'e.g. 20',
                helperText: 'How many pieces in one pack?',
                controller: _piecesPerPackController,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _isSoldByPack,
                      title: const Text("Sold by Pack"),
                      onChanged: (val) =>
                          setState(() => _isSoldByPack = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      value: _isSoldByPiece,
                      title: const Text("Sold by Piece"),
                      onChanged: (val) =>
                          setState(() => _isSoldByPiece = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Product Image',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade100,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                      : const Center(
                    child: Text(
                      'Tap to select image',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
