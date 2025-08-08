
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/product_stock.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/LooseStockProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductStockProvider.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/Provider/VariantProductProvider.dart';
import 'package:pocketpos/View/Components/Alert/AddOrEditStockDialog.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:pocketpos/View/Components/Modal/UpsertWidgets/ProductInitData.dart';
import 'package:pocketpos/View/Components/Modal/UpsertWidgets/openAddVariantDialog.dart';
import 'package:pocketpos/View/Components/Modal/UpsertWidgets/showImagePickerOptions.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';
import 'package:pocketpos/View/Components/Custom/CustomPillToggle.dart';
import 'package:pocketpos/View/Components/Custom/CustomTextField.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Modal/UpsertWidgets/ProductSubmitHelper.dart';
import 'package:pocketpos/View/Components/Modal/UpsertWidgets/helperWidgets.dart';
import 'package:pocketpos/View/Screen/Sub/BarcodeScannerScreen.dart';
import 'package:provider/provider.dart';

class UpsertProductModal extends StatefulWidget {
  final bool isVariant;
  final String Category;
  final Product? existingProduct;
  final Product? parentProduct;
  final bool? isRestock;

  const UpsertProductModal({super.key, this.isVariant = false, this.existingProduct, required this.Category, this.parentProduct, this.isRestock  = false});

  @override
  State<UpsertProductModal> createState() => _UpsertProductModalState();
}

class _UpsertProductModalState extends State<UpsertProductModal> {
  late var _nameController = TextEditingController();
  late var _piecesPerPackController = TextEditingController();
  late var _looseStockController = TextEditingController();
  late var _barcodeController = TextEditingController();

  String _selectedUnit = '';
  String? _selectedCategory;
  bool _isSoldByPack = false;
  bool _isSoldByPiece = false;
  bool _hasVariant = false;
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _hasStock = false;
   bool isAddingStock = false ;

  late List<Product> _variants = [];
   late List<ProductStock> _stock = [];

  @override
  void initState() {
    super.initState();

    final initData = initProductState(
      existingProduct: widget.existingProduct,
      parentProduct: widget.parentProduct,
      isVariant: widget.isVariant,
      passedCategory: widget.Category,
      updateLooseStock: _updateLooseStock,
    );

    _nameController = initData.nameController;
    _barcodeController = initData.barcodeController;
    _looseStockController = initData.looseStockController;
    _piecesPerPackController = initData.piecesPerPackController;
    _stock = initData.stock;
    _variants = initData.variants;

    _selectedCategory = initData.selectedCategory.isNotEmpty
        ? initData.selectedCategory
        : null;

    print(_selectedCategory);

    _selectedUnit = initData.selectedUnit;
    _isSoldByPack = initData.isSoldByPack;
    _isSoldByPiece = initData.isSoldByPiece;
    _hasVariant = initData.hasVariant;
    _selectedImage = initData.selectedImage;
    _hasStock = initData.hasStock;
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

  Color get themeAccent {
    final isEditing = widget.existingProduct != null;

    if (widget.isVariant) {
      return AppColor.textSecondary;
    }
    return isEditing ? AppColor.secondary : AppColor.primary;
  }



  @override
  Widget build(BuildContext context) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: AppColor.surface,
         child:   Padding(
           padding: widget.isVariant ? const EdgeInsets.all( 15) : const EdgeInsets.all(0),
           child: Consumer6<ProductProvider, StoreCategoryProvider,VariantProductProvider,LooseStockProvider,CurrencyProvider,ProductStockProvider>(
               builder: (context, productProvider, storeCategoryProvider,variantProductProvider,looseStockProvider,currencyProvider,productStockProvider, _)  {
                return Padding(
                    padding: EdgeInsets.only(
                      top: 0,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if(widget.isRestock == false)...[
                                Text(
                                  widget.existingProduct != null
                                      ? (widget.isRestock == true
                                      ? (widget.isVariant ? 'Restock Variant' : 'Restock Product')
                                      : (widget.isVariant ? 'Edit Variant' : 'Edit Product'))
                                      : (widget.isVariant ? 'Add Variant' : 'Add New Product'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: themeAccent,
                                  ),
                                ),

                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => showImagePickerOptions(
                                    context: context,
                                    onImagePicked: _pickImage, // this is your existing method
                                  ),
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColor.secondarySurface),
                                      borderRadius: BorderRadius.circular(10),
                                      color: AppColor.background.withOpacity(0.5),
                                    ),
                                    child: _selectedImage != null
                                        ? Stack(
                                      children: [
                                        // Image Layer
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        // Overlay Icon + Text
                                        Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.camera_alt_outlined, size: 24, color: Colors.white),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Tap to change image',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
                                Column(
                                  children: [
                                    CustomTextField(
                                      label: 'Product Name',
                                      hintText: 'Enter product name',
                                      controller: _nameController,
                                      prefixIcon: Icon(LucideIcons.box),
                                    ),
                                    const SizedBox(height: 5), // spacing
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            prefixIcon: Icon(Icons.qr_code),
                                            label: 'Barcode (Optional)',
                                            hintText: 'Scan or manually enter the barcode',
                                            controller: _barcodeController,
                                            keyboardType: TextInputType.text, // 🛠️ safer for barcode types
                                          ),
                                        ),
                                        SizedBox(
                                          height: 60,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: IconButton(
                                              icon: Icon(LucideIcons.scanLine,color: AppColor.primary,),
                                              tooltip: 'Scan Barcode',
                                              onPressed: () async {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => BarcodeScannerScreen(
                                                      onScanned: (barcode) {
                                                        // Update your text field or do whatever
                                                        print('Scanned barcode: $barcode');
                                                        if (!productProvider.barcodeExists(barcode)) {
                                                          setState(() {
                                                            _barcodeController.text = barcode;
                                                          });

                                                        } else {
                                                          Future.delayed(Duration(seconds: 1),(){
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) => CustomNotificationDialog(
                                                                onConfirm: () => Navigator.pop(context),
                                                                type: 'warning',
                                                                title: "Barcode Already Exist!",
                                                                content: "This barcode is already assigned to an existing product or variant. Please scan a different one.",
                                                              ),
                                                            );
                                                          });
                                                        }

                                                      },
                                                    ),
                                                  ),
                                                );

                                              },


                                            ),
                                          ),
                                        ),
                                      ],
                                    )


                                  ],
                                ),
                                const SizedBox(height: 5),
                                CustomFlatDropdown<String>(
                                  hint: 'Choose category',
                                  value: _selectedCategory ,
                                  items: storeCategoryProvider.visibleCategories,
                                  onChanged: (val) => setState(() => _selectedCategory = val),
                                  itemBuilder: (category) => Text(category),
                                  prefixIcon: Icons.category,
                                ),

                                const SizedBox(height: 20),

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomPillToggle(
                                        color: themeAccent,
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
                                        color: themeAccent,
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
                                  getSellingTypeGuide(isSoldByPack: _isSoldByPack, isSoldByPiece: _isSoldByPiece),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ],

                             // 🧩 Toggle "Add Stock Now?"
                              if (!isAddingStock && (_isSoldByPack || _isSoldByPiece))
                                ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Add Stock Now?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: themeAccent,
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
                                const SizedBox(height: 10),

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
                                                "Cost: ${currencyProvider.currencyFormat.format(stock.costPrice)}"
                                                    " | ${getUnitType(isSoldByPack: _isSoldByPack, isSoldByPiece: _isSoldByPiece)}\n"
                                                    "Retail: ${currencyProvider.currencyFormat.format(stock.retailPrice)}"
                                                    " | ${getUnitType(isSoldByPack: _isSoldByPack, isSoldByPiece: _isSoldByPiece)}",
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
                                                    packSize:  int.tryParse(_piecesPerPackController.text) ?? 0,


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

                              SizedBox(height: 10,),
                              // ➕ Add Stock Button
                              CustomButton(
                                isFilled: false,
                                borderColor: themeAccent,
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
                                      packSize:  int.tryParse(_piecesPerPackController.text) ?? 0,
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
                             if(widget.isRestock == false)...[
                               // 🧩 Toggle "Has Variants"
                               if (!widget.isVariant && (_isSoldByPack || _isSoldByPiece)) ...[
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(
                                       'Has Variants',
                                       style: TextStyle(
                                         fontSize: 14,
                                         fontWeight: FontWeight.w600,
                                         color: themeAccent,
                                       ),
                                     ),
                                     Switch(
                                       value: _hasVariant,
                                       activeColor: themeAccent,
                                       activeTrackColor: themeAccent.withOpacity(0.5),
                                       onChanged: (val) {

                                         if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                                         showDialog(
                                           context: context,
                                           builder: (context) => CustomNotificationDialog(
                                             title: "Missing Category",
                                             content: "Please select a category first before enabling variants.",
                                             type: 'warning',
                                             onConfirm: () => Navigator.pop(context),
                                           ),
                                         );
                                         return;
                                       }

                                       // Safe to toggle
                                         setState(() => _hasVariant = val);
                                       },
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
                                   isFilled: false,
                                   borderColor: themeAccent,
                                   icon: Icons.add_circle_outline,
                                   text: "Add Variant",
                                   onPressed: () async {
                                     await openAddVariantDialog(
                                     context: context,
                                     productProvider: productProvider,
                                     existingProduct: widget.existingProduct,
                                     selectedUnit: _selectedUnit,
                                     isSoldByPack: _isSoldByPack,
                                     isSoldByPiece: _isSoldByPiece,
                                     selectedCategory: _selectedCategory,
                                     piecesPerPackText: _piecesPerPackController.text,
                                     selectedImage: _selectedImage,
                                     nameController: _nameController,
                                     categoryFromParent: widget.Category,
                                     onVariantAdded: (newVariant) {
                                       setState(() => _variants.add(newVariant));
                                     },
                                     );

                                   },
                                 ),
                                 const SizedBox(height: 16),

                               ],
                             ],
                              const SizedBox(height: 16),
                           Row(
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
                                            type: 'warning',
                                            onConfirm: () => Navigator.pop(context),
                                          ),
                                        );
                                        return;
                                      }

                                      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => CustomNotificationDialog(
                                            title: "Missing Category",
                                            content: "Please select a category first before enabling variants.",
                                            type: 'warning',
                                            onConfirm: () => Navigator.pop(context),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => _isSubmitting = true);
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      submitProductHelper(
                                        context: context,
                                        productProvider: productProvider,
                                        variantProductProvider: variantProductProvider,
                                        looseStockProvider: looseStockProvider,
                                        isSoldByPack: _isSoldByPack,
                                        isSoldByPiece: _isSoldByPiece,
                                        name: _nameController.text.trim(),
                                        barcode: _barcodeController.text.trim(),
                                        isEditing: widget.existingProduct != null,
                                        isVariant: widget.isVariant,
                                        hasVariant: _hasVariant,
                                        selectedUnit: _selectedUnit,
                                        selectedCategory: _selectedCategory,
                                        imagePath: _selectedImage?.path,
                                        piecesPerPackText: _piecesPerPackController.text,
                                        stock: _stock,
                                        variants: _variants,
                                        existingProduct: widget.existingProduct,
                                        parentProduct: widget.parentProduct,
                                        looseStockText: _looseStockController.text,
                                        nameController: _nameController,
                                        barcodeController: _barcodeController,
                                        piecesPerPackController: _piecesPerPackController,
                                        looseStockController: _looseStockController,
                                      );

                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                            ]

                      ),
                    ),

                );
              }
            ),
         ),
        );

  }
}
