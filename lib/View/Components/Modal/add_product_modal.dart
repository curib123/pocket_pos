import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddProductModal {
  static void show(BuildContext context, {bool isEdit = false, bool isStock = false, Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        // Fix: wrap with Builder to access a valid MediaQuery context
        return Builder(
          builder: (innerContext) {
            final bottomInset = MediaQuery.of(innerContext).viewInsets.bottom;
            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _ModalContent(isEdit: isEdit, isStock: isStock, product: product),
              ),
            );
          },
        );
      },
    );
  }
}


class _ModalContent extends StatefulWidget {
  final bool isEdit;
  final bool isStock;
  final Product? product;

  const _ModalContent({Key? key, this.isEdit = false, this.isStock = false, this.product}) : super(key: key);

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
  Product? _editingProduct;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.product != null || widget.isStock && widget.product != null) {
      _selectedProductToRestock = widget.product;
      _editingProduct = widget.product;
      final p = _editingProduct!;
      _nameController.text = p.name;
      _costController.text = p.costPrice.toString();
      _retailController.text = p.retailPrice.toString();
      _descController.text = p.description;
      _selectedCategory = p.category;
      if (p.imageUrl.isNotEmpty) _pickedImage = XFile(p.imageUrl);
      if (p.batches.isNotEmpty) {
        _selectedBatchIndex = 0;
        if(!widget.isStock){
          _quantityController.text = p.batches[0].quantity.toString();
          _kiloQuantityController.text = p.batches[0].kiloQuantity.toString();
        }else{
          _quantityController.text = 0.toString();
          _kiloQuantityController.text = 0.toString();
        }
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

      if (_selectedProductToRestock != null) {
        final u = _selectedProductToRestock!;
        u.name = _nameController.text.trim();
        if (!widget.isStock) {
          u.imageUrl = savedImagePath.isNotEmpty ? savedImagePath : u.imageUrl;
        }
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

      if (widget.isEdit && _editingProduct != null) {
        final u = _editingProduct!;
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


      final product = Product(
        id: id,
        name: _nameController.text.trim(),
        costPrice: double.tryParse(_costController.text) ?? 0,
        retailPrice: double.tryParse(_retailController.text) ?? 0,
        unit: "Unit",
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
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Try again."), backgroundColor: AppColor.warning),
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
            hintText: "Choose Batch to Edit",
            prefixIcon: const Icon(LucideIcons.layers),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: List.generate(widget.product!.batches.length, (i) {
            return DropdownMenuItem<int>(
              value: i,
              child: Text("Batch ${i + 1}", style: const TextStyle(fontSize: 13)),
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

  Widget _imagePickerPreview() {
    if (widget.isStock) return const SizedBox.shrink();
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
                  Text("Tap to take product photo", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _modernInput(TextEditingController c, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                  ),
                  Text(
                    widget.isStock
                        ? "Restock Existing Product"
                        : widget.isEdit
                        ? "Edit Product Details"
                        : "Add a New Product",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (!widget.isEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "Search for a product (if restocking)",
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  Autocomplete<Product>(
                    displayStringForOption: (p) => p.name,
                    optionsBuilder: (val) => productProvider.products
                        .where((p) => p.name.toLowerCase().contains(val.text.toLowerCase()))
                        .take(5),
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      controller.text = _nameController.text;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        onChanged: (val) => _nameController.text = val,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        decoration: InputDecoration(
                          hintText: "Search or enter product name",
                          prefixIcon: Icon(LucideIcons.search),
                          filled: true,
                          fillColor: AppColor.success.withOpacity(0.10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    onSelected: (selected) {
                      setState(() {
                        _selectedProductToRestock = selected;
                        _nameController.text = selected.name;
                        if (!widget.isStock) {
                          _costController.text = selected.costPrice.toString();
                          _retailController.text = selected.retailPrice.toString();
                          _descController.text = selected.description;
                          _selectedCategory = selected.category;
                          _pickedImage = selected.imageUrl.isNotEmpty ? XFile(selected.imageUrl) : null;
                        }
                        _quantityController.clear();
                        _kiloQuantityController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  if (_selectedProductToRestock != null) ...[
                    const SizedBox(height: 10),
                    const Text("Recent Restocks", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _selectedProductToRestock!.batches.reversed.take(5).map((b) {
                          final formattedDate = "${b.date.year}-${b.date.month.toString().padLeft(2, '0')}-${b.date.day.toString().padLeft(2, '0')}";
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "$formattedDate — ${b.quantity} pcs / ${b.kiloQuantity} kg",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  if (!widget.isStock) ...[
                    _batchDropdown(),
                    _modernInput(_costController, "Purchase Price", LucideIcons.dollarSign, type: TextInputType.number),
                    _modernInput(_retailController, "Selling Price", LucideIcons.badgeDollarSign, type: TextInputType.number),
                    _modernDropdown("Select Category", LucideIcons.layoutGrid, _selectedCategory,
                        catProv.visibleCategories, (val) => setState(() => _selectedCategory = val)),
                    _modernInput(_descController, "Product Description", LucideIcons.stickyNote, maxLines: 2),
                    _imagePickerPreview(),
                  ],
                  if(widget.isStock)  const SizedBox(height: 5),
                  const Text("Add New Batch of Stocks", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  _modernInput(_quantityController, "Stock Quantity (pieces)", LucideIcons.shoppingBag, type: TextInputType.number),
                  _modernInput(_kiloQuantityController, "Stock Quantity (kilograms)", LucideIcons.scale, type: TextInputType.number),

                  const SizedBox(height: 20),

                  CustomButton(
                    icon: LucideIcons.save,
                    color: AppColor.success,
                    label: widget.isEdit
                        ? "Save Changes"
                        : (widget.isStock || _selectedProductToRestock != null ? "Confirm Restock" : "Add Product"),
                    onPressed: () {
                      if (_quantityController.text.isEmpty) _quantityController.text = "0";
                      if (_kiloQuantityController.text.isEmpty) _kiloQuantityController.text = "0";
                      if (_descController.text.isEmpty) _descController.text = "No Description";
                      _submit(context);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
