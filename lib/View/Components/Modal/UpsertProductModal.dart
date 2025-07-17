import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_stock_inventory/Helper/ProductUnits.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/product_stock.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/LooseStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_stock_inventory/Provider/VariantProductProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/AddOrEditStockDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomPillToggle.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';
import 'package:provider/provider.dart';

class UpsertProductModal extends StatefulWidget {
  final bool isVariant;
  final String Category;
  final Product? existingProduct;
  final Product? parentProduct;

  const UpsertProductModal({super.key, this.isVariant = false, this.existingProduct, required this.Category, this.parentProduct});

  @override
  State<UpsertProductModal> createState() => _UpsertProductModalState();
}

class _UpsertProductModalState extends State<UpsertProductModal> {
  final _nameController = TextEditingController();
  final _piecesPerPackController = TextEditingController();
  final _looseStockController = TextEditingController();

  String? _selectedUnit;
  String? _selectedCategory;
  bool _isSoldByPack = false;
  bool _isSoldByPiece = false;
  bool _hasVariant = false;
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _hasStock = false;
   bool isAddingStock = false ;

   final List<String> _units = ProductUnits.units;
  final List<Product> _variants = [];
   final List<ProductStock> _stock = [];

  @override
  void initState() {
    super.initState();

    // 👀 Set initial category if passed from parent screen
    if (widget.Category.isNotEmpty) {
      _selectedCategory = widget.Category;
    }

    final p = widget.existingProduct;
    final parent = widget.parentProduct;

    if (p != null) {
      // 🛠️ Editing an existing product
      _nameController.text = p.name;
      _selectedCategory = p.category;
      _selectedUnit = p.unit;
      _isSoldByPack = p.isSoldByPack;
      _isSoldByPiece = p.isSoldByPiece;
      _hasVariant = p.hasVariant;
      _selectedImage = (p.imagePath?.isNotEmpty == true) ? File(p.imagePath!) : null;
      _variants.addAll(p.variants);

      // ✅ Populate pieces per pack
      _piecesPerPackController.text = p.piecesPerPack.toString();

      // ✅ Populate loose stock only if it exists
      _looseStockController.text = p.looseStock?.toString() ?? '';

      // ✅ Load stock batches
      _stock.addAll(p.stocks);
      _hasStock = _stock.isNotEmpty;

    } else if (widget.isVariant && parent != null) {
      // 🧬 Adding a new variant (inherits from parent)
      _selectedCategory = parent.category;
      _selectedUnit = parent.unit;
      _isSoldByPack = parent.isSoldByPack;
      _isSoldByPiece = parent.isSoldByPiece;

      // ✅ Inherit piecesPerPack from parent product
      _piecesPerPackController.text = parent.piecesPerPack.toString();

      // ⚠️ Loose stock should be handled separately for new variants

    } else {
      // 🆕 Creating brand new product
      _piecesPerPackController.text = '0'; // Default value
    }

    // 🧠 Always listen to piecesPerPack changes to update loose stock live
    _piecesPerPackController.addListener(_updateLooseStock);

    // 🚀 Initialize calculated loose stock right away
    _updateLooseStock();
  }



  void _updateLooseStock() {
    final piecesPerPack = int.tryParse(_piecesPerPackController.text);
    if (piecesPerPack != null && piecesPerPack > 0) {
      final totalQuantity = _stock.fold<int>(0, (sum, s) => sum + s.quantity);
      final totalLoosePieces = piecesPerPack * totalQuantity;
      _looseStockController.text = totalLoosePieces.toString();
    } else {
      _looseStockController.text = ''; // Clear if invalid or empty
    }
  }


  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Color get themeAccent => widget.isVariant ? AppColor.success : AppColor.primary;

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
  String getSellingTypeGuide() {
    if (_isSoldByPack && _isSoldByPiece) {
      return 'Customers can buy either full packs or individual pieces. e.g. a box of canned soda or a single can.';
    } else if (_isSoldByPack) {
      return 'This product is only sold in full packs. e.g. a 6-pack of bottled water.';
    } else if (_isSoldByPiece) {
      return 'This product is only sold per piece. e.g. a single candy bar or bottled drink.';
    } else {
      return 'Choose at least one selling method: pack, piece, or both. e.g. You might sell bottled water by the case (pack) or by the bottle (piece).';

    }
  }

  String get unitType {
    if (_isSoldByPack) return 'pack';
    if (_isSoldByPiece) return 'piece';
    return 'unit';
  }

  Future<void> _openAddVariantDialog() async {
    final parent = Product(
      id: widget.existingProduct?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      unit: _selectedUnit ?? 'pcs',
      isSoldByPack: _isSoldByPack,
      isSoldByPiece: _isSoldByPiece,
      category: _selectedCategory ?? "Uncategorized",
      piecesPerPack: int.tryParse(_piecesPerPackController.text.trim()) ?? 1,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      imagePath: _selectedImage?.path ?? '',
      hasVariant: true,
      variants: [],
      stocks: [],
      logs: [],
      looseStock: null,
    );

    final Product? newVariant = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.80,
          initialChildSize: 0.75,
          minChildSize: 0.6,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: widget.Category,
                    isVariant: true,
                    existingProduct: null, // optional if you want fresh variant
                    parentProduct: parent,  // ✅ this will be the new param
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (newVariant != null) {
      setState(() {
        _variants.add(newVariant);
      });
    }
  }

  void _submitProduct(
      ProductProvider productProvider,
      VariantProductProvider variantProductProvider,
      LooseStockProvider looseStockProvider,
      ProductStockProvider productStockProvider,
      ) async {
    // Prevent saving if no selling method selected
    if (!_isSoldByPack && !_isSoldByPiece) {
      showDialog(
        context: context,
        builder: (context) => CustomNotificationDialog(
          title: "Missing Selling Method",
          content: "Please select at least one selling method: Pack, Piece, or both.",
          onConfirm: () {
            Navigator.pop(context);
            setState(() => _isSubmitting = false);
          },
          type: 'warning',
        ),
      );
      return;
    }

    final isEditing = widget.existingProduct != null;
    final productId = isEditing
        ? widget.existingProduct!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final updatedStocks = _stock.map((stock) => stock.copyWith(productId: productId)).toList();
    final updatedVariants = _variants.map((variant) => variant.copyWith(isVariant: true)).toList();

    final product = Product(
      id: productId,
      name: _nameController.text.trim(),
      category: _selectedCategory ?? "Uncategorized",
      unit: _selectedUnit ?? 'pcs',
      piecesPerPack: _isSoldByPiece
          ? int.tryParse(_piecesPerPackController.text.trim()) ?? 0
          : 0,
      isSoldByPack: _isSoldByPack,
      isSoldByPiece: _isSoldByPiece,
      imagePath: _selectedImage?.path ?? '',
      createdAt: isEditing ? widget.existingProduct!.createdAt : DateTime.now(),
      lastModified: DateTime.now(),
      deletedAt: null,
      stocks: updatedStocks, // ✅ Preserve updated stocks
      logs: widget.existingProduct?.logs ?? [],
      hasVariant: _hasVariant,
      variants: _hasVariant ? updatedVariants : [],
      looseStock: null, // Will be handled separately
    );


    try {
      if (widget.isVariant || widget.existingProduct!.isVariant) {
        final parentId = widget.existingProduct!.isVariant
            ? variantProductProvider.getParentProductIdFromVariantId(productId)
            : widget.existingProduct?.id ?? _selectedCategory ?? 'unknown';

        print("Parent ID: $parentId");
        print("Product ID: $productId");
        print("Prouct : ${product.toMap()}");
        await variantProductProvider.upsertVariant(parentId.toString(), product);

        Navigator.pop(context, product);
      } else {

        await productProvider.upsertProduct(product);

        if (_isSoldByPiece) {
          final looseQty = int.tryParse(_looseStockController.text.trim()) ?? 0;
          await looseStockProvider.upsertLooseStock(productId, looseQty);
        } else {
          await looseStockProvider.deleteLooseStock(productId);
        }

        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => CustomNotificationDialog(
            onConfirm: () => Navigator.pop(context),
            type: 'success',
            title: isEditing ? "Product Updated" : "Product Added",
            content: isEditing
                ? "The product was successfully updated!"
                : "The product was successfully added!",
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving product: $e");
      showDialog(
        context: context,
        builder: (context) => CustomNotificationDialog(
          onConfirm: () => Navigator.pop(context),
          type: 'error',
          title: "Failed to Save",
          content: "Something went wrong while saving the product.\nError: $e",
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: AppColor.surface,
          child: Padding(
            padding: EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child:   Consumer6<ProductProvider, StoreCategoryProvider,VariantProductProvider,LooseStockProvider,CurrencyProvider,ProductStockProvider>(
            builder: (context, productProvider, storeCategoryProvider,variantProductProvider,looseStockProvider,currencyProvider,productStockProvider, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.existingProduct != null
                            ? (widget.isVariant ? 'Edit Variant' : 'Edit Product')
                            : (widget.isVariant ? 'Add Variant' : 'Add New Product'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColor.border),
                            borderRadius: BorderRadius.circular(10),
                            color: AppColor.background.withOpacity(0.5),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                              : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 24, color: AppColor.textSecondary),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(color: AppColor.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Product Name',
                        hintText: 'Enter product name',
                        helperText: 'This will appear in listings and receipts',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 10),
                      CustomFlatDropdown<String>(
                        hint: 'Choose category',
                        helperText: 'Group similar items together',
                        value: _selectedCategory,
                        items: storeCategoryProvider.visibleCategories,
                        onChanged: (val) => setState(() => _selectedCategory = val),
                        itemBuilder: (category) => Text(category),
                        prefixIcon: Icons.category,
                      ),
                      const SizedBox(height: 20),
                      CustomFlatDropdown<String>(
                        hint: 'Choose unit',
                        helperText: 'e.g. pcs, ml, kg',
                        value: _selectedUnit,
                        items: _units,
                        onChanged: (val) => setState(() => _selectedUnit = val),
                        itemBuilder: (unit) => Text(unit),
                        prefixIcon: Icons.scale,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CustomPillToggle(
                              label: "Sold by Pack",
                              isSelected: _isSoldByPack,
                              onTap: () => setState(() {
                                _isSoldByPack = !_isSoldByPack;
                                if (!_isSoldByPack) _piecesPerPackController.clear();
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomPillToggle(
                              label: "Sold by Piece",
                              isSelected: _isSoldByPiece,
                              onTap: () => setState(() {
                                _isSoldByPiece = !_isSoldByPiece;
                                if (!_isSoldByPiece) _looseStockController.clear();
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        getSellingTypeGuide(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColor.textSecondary,
                        ),
                      ),

                     // 🧩 Toggle "Add Stock Now?"
                      if (!isAddingStock && (_isSoldByPack || _isSoldByPiece))
                        ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Stock Now?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Switch(
                              value: _hasStock,
                              activeColor: themeAccent,
                              activeTrackColor: themeAccent.withOpacity(0.3),
                              onChanged: (val) => setState(() => _hasStock = val),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Enable this if you want to add stock now.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                       // 🧩 Show Stocks and Add/Edit/Delete UI
                      if (_hasStock && !isAddingStock) ...[
                        if (_isSoldByPack && _isSoldByPiece) ...[
                          CustomTextField(
                            label: 'Pieces per Pack',
                            hintText: 'e.g. 20',
                            helperText: 'How many pieces per pack?',
                            controller: _piecesPerPackController,
                            keyboardType: TextInputType.number,
                          ),

                          CustomTextField(
                            label: _isSoldByPack ? 'Pieces (Auto)' : 'Number of Pieces',
                            hintText: _isSoldByPack ? 'Calculated automatically' : 'e.g. 100',
                            helperText: (_isSoldByPack && _isSoldByPiece)
                                ? 'This field is auto-calculated based on pack quantity'
                                : (_isSoldByPack
                                ? (_piecesPerPackController.text.isEmpty ||
                                int.tryParse(_piecesPerPackController.text) == 0)
                                ? 'Enter pieces per pack to enable auto-calculation'
                                : 'This value is auto-calculated from stock × pieces per pack'
                                : 'Enter the total number of individual items in stock'),
                            controller: _looseStockController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        if (_stock.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Existing Stocks",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          ..._stock.map(
                                (stock) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:themeAccent.withOpacity(0.01),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 📊 Stock Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Quantity: ${stock.quantity}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Cost: ${currencyProvider.currencyFormat.format(stock.costPrice)} | $unitType \n "
                                                  "Retail: ${currencyProvider.currencyFormat.format(stock.retailPrice)} | $unitType",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Date Added: ${DateFormat('MMM dd, yyyy').format(stock.lastModified)}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // ✏️ Edit & Delete Buttons
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 25, color: Colors.orange),
                                            tooltip: 'Edit Stock',
                                            splashRadius: 20,
                                            onPressed: () async {
                                              final edited = await showDialog<ProductStock>(
                                                context: context,
                                                builder: (_) => AddOrEditStockDialog(
                                                  productId: stock.productId,
                                                  existingStock: stock,
                                                  isSoldByPack: _isSoldByPack,
                                                  isSoldByPiece: _isSoldByPiece,
                                                ),
                                              );

                                              if (edited != null) {
                                                setState(() {
                                                  final index = _stock.indexWhere((s) => s.id == edited.id);
                                                  if (index != -1) _stock[index] = edited;
                                                  _updateLooseStock();
                                                });
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 25, color: Colors.red),
                                            tooltip: 'Delete Stock',
                                            splashRadius: 20,
                                            onPressed: () async {
                                              await showDialog(
                                                context: context,
                                                builder: (_) => CustomConfirmDialog(
                                                  title: "Delete Stock?",
                                                  content: "Are you sure you want to remove this stock entry?",
                                                  icon: Icons.delete_outline,
                                                  iconColor: Colors.redAccent,
                                                  cancelText: "Cancel",
                                                  confirmText: "Delete",
                                                  onConfirm: () {
                                                    setState(() {
                                                      _stock.removeWhere((s) => s.id == stock.id);
                                                      _updateLooseStock();
                                                    });
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                            ,
                          ),
                        ],

                        const SizedBox(height: 10),

                        // ➕ Add Stock Button
                        CustomButton(
                          icon: Icons.add_circle_outline,
                          text: "Add Stock",
                          onPressed: () async {
                            final productId = widget.existingProduct?.id ?? "temp-${DateTime.now().millisecondsSinceEpoch}";
                            final stock = await showDialog<ProductStock>(
                              context: context,
                              builder: (_) => AddOrEditStockDialog(
                                productId: productId,
                                isSoldByPack: _isSoldByPack,
                                isSoldByPiece: _isSoldByPiece,
                              ),
                            );

                            if (stock != null) {
                              setState(() {
                                _stock.add(stock);
                                _updateLooseStock();
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),
                      ],

                      // 🧩 Toggle "Has Variants"
                      if (!widget.isVariant) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Has Variants',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Switch(
                              value: _hasVariant,
                              activeColor: themeAccent,
                              activeTrackColor: themeAccent.withOpacity(0.5),
                              onChanged: (val) => setState(() => _hasVariant = val),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Enable if this product has multiple types or versions.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // 🧩 Show Variant List & Add Button
                      if (_hasVariant && !widget.isVariant) ...[
                        if (_variants.isNotEmpty) ...[
                          const Text("Added Variants", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          ..._variants.map(
                                (v) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  // 📸 Image preview
                                  (v.imagePath != null && v.imagePath!.isNotEmpty)
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(v.imagePath!),
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                      : const Icon(Icons.image_not_supported_outlined, size: 50),

                                  const SizedBox(width: 12),

                                  // 🧾 Variant Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Unit: ${v.unit}",
                                          style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                                        ),
                                        if (v.stocks.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "Qty: ${v.stocks.first.quantity}",
                                            style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),

                                  // ✏️ Actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        tooltip: "Edit Variant",
                                        onPressed: () async {
                                          final editedVariant = await showModalBottomSheet<Product>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                            ),
                                            builder: (_) => DraggableScrollableSheet(
                                              expand: false,
                                              maxChildSize: 0.80,
                                              initialChildSize: 0.60,
                                              minChildSize: 0.6,
                                              builder: (_, controller) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                                ),
                                                child: Material(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                                                  color: Colors.white,
                                                  child: SafeArea(
                                                    top: false,
                                                    child: SingleChildScrollView(
                                                      controller: controller,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                                      child: UpsertProductModal(
                                                        Category: _selectedCategory ?? '',
                                                        isVariant: true,
                                                        existingProduct: v,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );

                                          if (editedVariant != null) {
                                            setState(() {
                                              final index = _variants.indexWhere((variant) => variant.id == editedVariant.id);
                                              if (index != -1) _variants[index] = editedVariant;
                                            });
                                            SnackbarService.showSuccess("✅ Variant updated!");
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_outlined, color: Colors.redAccent),
                                        tooltip: "Delete Variant",
                                        onPressed: () async {
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (context) => CustomConfirmDialog(
                                              title: "Delete Variant?",
                                              content: "Are you sure you want to delete '${v.name}'?",
                                              onCancel: () => Navigator.pop(context),
                                              onConfirm: () {
                                                setState(() {
                                                  _variants.removeWhere((variant) => variant.id == v.id);
                                                });
                                                SnackbarService.showSuccess("🗑️ Variant deleted!");
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),


                          const SizedBox(height: 5),
                        ],

                        CustomButton(
                          icon: Icons.add_circle_outline,
                          text: "Add Variant",
                          onPressed: _openAddVariantDialog,
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 10,),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                backgroundColor: themeAccent,
                                icon: Icons.check_circle_outline,
                                text: _isSubmitting
                                    ? (widget.existingProduct != null
                                    ? "Saving..."
                                    : "Adding...")
                                    : (widget.existingProduct != null
                                    ? (widget.isVariant ? "Update " : "Update ")
                                    : (widget.isVariant ? "Add Variant " : "Add Product ")),
                                isDisabled: _isSubmitting,
                                onPressed: () async {
                                  if (_nameController.text.trim().isEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => CustomNotificationDialog(
                                        title: "Missing Product Name",
                                        content: "Please enter a name for this product.",
                                        onConfirm: () => Navigator.pop(context),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _isSubmitting = true);
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  _submitProduct(
                                    productProvider,
                                    variantProductProvider,
                                    looseStockProvider,
                                    productStockProvider,
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: CustomButton(
                                borderColor: themeAccent,
                                isFilled: false,
                                icon: Icons.cancel_rounded,
                                text: "Cancel",
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  );
                }
              ),
            ),
          ),
        );


  }
}
