import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Helper/Enums/enum.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/VariantProductProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomStepper.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomSwitchPill.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_stock_inventory/View/Components/Modal/UpsertProductModal.dart';
import 'package:mobile_stock_inventory/View/Components/ResponsiveText.dart';
import 'package:provider/provider.dart';

class ProductDetailModal {
  static void show(BuildContext context, String productId,ModalAsVariant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets;
        return FractionallySizedBox(
          heightFactor: 0.80,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: _ProductDetailContent(productId: productId,ModalAsVariant: ModalAsVariant),
          ),
        );
      },
    );
  }
}

class _ProductDetailContent extends StatefulWidget {
  final String productId;
  final bool? ModalAsVariant ;
  const _ProductDetailContent({required this.productId,  this.ModalAsVariant});

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {

  bool isUsePackSwitch = false;
  double price = 0;
  double cost = 0;
  String unit = '';
  bool usePack = false;
  bool usePiece = false;
  double qty = 0;
  double quantityChosen = 0;
  bool useQtyInput = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final product = context.read<ProductProvider>().getProductById(widget.productId);
    if (product == null) return;

    usePack = product.isSoldByPack;
    usePiece = product.isSoldByPiece;
    unit = product.unit ?? "unit";

    final latest = product.stocks.isNotEmpty ? product.stocks.last : null;
    if (latest == null) return;

    final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);

    final bool isPieceOnly = !product.isSoldByPack && product.isSoldByPiece;
    final bool isPackView = product.isSoldByPack && isUsePackSwitch;

    price = isPieceOnly
        ? latest.retailPrice
        : isPackView
        ? latest.retailPrice
        : latest.retailPrice / perPack;

    cost = isPieceOnly
        ? latest.costPrice
        : isPackView
        ? latest.costPrice
        : latest.costPrice / perPack;

    qty = isPieceOnly
        ? product.totalQuantity.toDouble()
        : isPackView
        ? product.totalQuantity.toDouble()
        : product.totalQuantityByPieces.toDouble();
  }


  Widget get unitType {
    final label = isUsePackSwitch
        ? (usePack ? 'Pack' : 'Piece')
        : (usePiece ? 'Piece' : 'Pack');

    return Row(children: [_buildTag(label)]);
  }

  String formatNumber(num value) => NumberFormat.decimalPattern().format(value);

  void _editVariant(BuildContext context, Product variant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.95,
          initialChildSize: 0.9,
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
                    Category: '',
                    existingProduct: variant,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteVariant(BuildContext context, String parentId, String ,VariantProductProvider variantProductProvider, String variantId) {
    showDialog(
      context: context,
      builder: (context) => CustomConfirmDialog(
        title: "Delete Variant",
        content: "Are you sure you want to delete this variant?\nThis action cannot be undone.",
        onConfirm: () {
          variantProductProvider.deleteVariant(parentId, variantId);
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().getProductById(widget.productId);
    final currency = context.read<CurrencyProvider>().currencyFormat;

    if (product == null) {
      return const Center(child: Text("Product not found"));
    }

    final hasImage = product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        File(product.imagePath!).existsSync();

    return SafeArea(
      child: Consumer3<ProductProvider, ProductStockProvider,VariantProductProvider>(
        builder: (context, productProvider, productStockProvider,variantProductProvider, _) {
          return Scaffold(
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Add to Cart',
                            icon: Icons.shopping_cart_outlined,
                            isFilled: false,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'Proceed',
                            icon: Icons.check_circle_outline,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Selling Switch ---
                  if (product.isSoldByPiece && product.isSoldByPack)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.center,
                        child: CustomSwitchPill(
                          options: ['Pack', 'Pcs'],
                          selected: isUsePackSwitch ? 'Pack' : 'Pcs',
                          onSelected: (label) => setState(() {
                            isUsePackSwitch = label == 'Pack';
                            final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);
                            final stock = product.stocks.isNotEmpty ? product.stocks.last : null;

                            price = stock != null
                                ? (!product.isSoldByPack && product.isSoldByPiece)
                                ? stock.retailPrice
                                : isUsePackSwitch
                                ? stock.retailPrice
                                : stock.retailPrice / perPack
                                : 0;

                            cost = stock != null
                                ? (!product.isSoldByPack && product.isSoldByPiece)
                                ? stock.costPrice
                                : isUsePackSwitch
                                ? stock.costPrice
                                : stock.costPrice / perPack
                                : 0;
                            qty = (!product.isSoldByPack && product.isSoldByPiece)
                                ? product.totalQuantity.toDouble()
                                : isUsePackSwitch
                                ? product.totalQuantity.toDouble()
                                : product.totalQuantityByPieces.toDouble();

                            quantityChosen = quantityChosen > qty ? qty : quantityChosen;
                          }),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // --- Product Image & Price Tag ---
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 130,
                          child: hasImage
                              ? Image.file(
                            File(product.imagePath!),
                            key: UniqueKey(),
                            fit: BoxFit.contain,
                          )
                              : Container(
                            color: AppColor.border.withOpacity(0.3),
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 32, color: AppColor.primary),
                            ),
                          ),
                        ),
                      ),

                      // Action button (top-right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: product.isVariant
                            ? _goToMainProductButton(variantProductProvider)
                            : _deleteProductButton(productProvider),
                      ),

                      Positioned(
                        bottom: 5,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // --- Price Tag ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              decoration: BoxDecoration(
                                color:  AppColor.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sell, size: 15, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    currency.format(price),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 5),

                            // --- Cost Tag ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:  AppColor.warning,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_atm_outlined, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cost: ${currency.format(cost)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),



                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- Product Info Section ---
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _getFontSizeForName(product.name) + 5,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 🏷 Selling types & category
                        if (usePack || usePiece)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: -4,
                              alignment: WrapAlignment.center,
                              children: [
                                if (product.category != null) _buildTag(product.category!),
                                if (product.isVariant) _buildTag("Variant"),
                                if (!product.isVariant) _buildTag("Main Product"),
                                if (usePack) _buildTag('Pack'),
                                if (usePiece) _buildTag('Piece'),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            if (!product.isSoldByPack && product.isSoldByPiece)
                              _buildStockLabel('Available Piece: ${formatNumber(product.totalQuantity)}')
                            else if (isUsePackSwitch)
                              _buildStockLabel('Available Pack: ${formatNumber(product.totalQuantity)}')
                            else
                              _buildStockLabel('Available Piece: ${formatNumber(product.totalQuantityByPieces)}'),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- Action Buttons ---
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Edit',
                                icon: Icons.edit,
                                isFilled: false,
                                borderColor: AppColor.warning,
                                onPressed: () => _openEditSheet(product),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: CustomButton(
                                text: 'Restock',
                                icon: Icons.inventory_2,
                                isFilled: false,
                                borderColor: AppColor.primary,
                                onPressed: () => _openRestockSheet(product),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!product.isVariant)
                              Expanded(
                                child: CustomButton(
                                  text: 'Add Variant',
                                  isFilled: false,
                                  borderColor: AppColor.success,
                                  onPressed: () => _openAddVariantSheet(context, product),
                                ),
                              ),
                          ],
                        ),

                        // --- Variants Section ---

                         if(!product.isVariant)...[
                           Padding(
                             padding: const EdgeInsets.all(10.0),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text("Variants",style: TextStyle(color: AppColor.textSecondary,fontSize: 16,fontWeight: FontWeight.bold),),
                                 Text(product.variants.length.toString(),style: TextStyle(color: AppColor.textSecondary,fontSize: 16,fontWeight: FontWeight.bold),),
                               ],
                             ),
                           ),
                           ...product.variants.map((variant) =>
                               _buildVariantCard(context, variant, product, variantProductProvider)),
                         ],

                        SizedBox(height: 10 ),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: CustomStepperField(
                                  value: quantityChosen.toInt(),
                                  min: 0,
                                  max: qty.toInt(),
                                  useTextInput: useQtyInput,
                                  onChanged: (val) => setState(() {
                                    quantityChosen = val.toDouble();
                                    // Auto-switch to input mode if reaching/exceeding max qty
                                    if (val >= qty.toInt()) {
                                      useQtyInput = true;
                                    }
                                  }),
                                  themeColor: AppColor.primary,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: CustomSwitchPill(
                                  options: ['Stepper', 'Input'],
                                  selected: useQtyInput ? 'Input' : 'Stepper',
                                  onSelected: (val) => setState(() {
                                    useQtyInput = (val == 'Input');
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10 ),
                      ],
                    ),
                ],
              ),
            ),



          );
        },
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColor.primary,
        ),
      ),
    );
  }

  Widget _buildStockLabel(String label) {
    // Adjust font size based on label length
    double fontSize;
    if (label.length <= 20) {
      fontSize = 14;
    } else if (label.length <= 35) {
      fontSize = 13;
    } else {
      fontSize = 12;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: AppColor.textSecondary.withOpacity(0.7),
        ),
      ),
    );
  }

  double _getFontSizeForName(String name) {
    return (22 - (name.length * 0.3)).clamp(10.0, 16.0);
  }


  Widget _goToMainProductButton(VariantProductProvider variantProductProvider) {
    return TextButton.icon(
      onPressed: () {
        if (widget.ModalAsVariant == true) {
          Navigator.pop(context);
        } else {
          final parentId = variantProductProvider.getParentProductIdFromVariantId(widget.productId);
          if (parentId != null) {
            showDialog(
              context: context,
              builder: (context) => CustomConfirmDialog(
                title: "Go to Main Product",
                content: "Are you sure you want to view the main product?\nYou’ll leave this product view.",
                onConfirm: () {
                  Navigator.pop(context);
                  ProductDetailModal.show(context, parentId, false);
                },
              ),
            );
          }
        }
      },
      icon: const Icon(LucideIcons.cornerUpLeft, color: Colors.white, size: 16),
      label: const Text(
        "Go Main",
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
        backgroundColor: Colors.black.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _deleteProductButton(ProductProvider productProvider) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => CustomConfirmDialog(
            title: "Delete Product",
            content: "Are you sure you want to delete this product?\nThis action cannot be undone.",
            onConfirm: () {
              productProvider.deleteProduct(widget.productId);
              Navigator.pop(context);
            },
          ),
        );
      },
      icon: const Icon(LucideIcons.trash, color: Colors.white, size: 18),
      tooltip: "Delete Product",
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black12.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }


  void _openEditSheet(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.7,
          minChildSize: 0.65,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: '',
                    existingProduct: p,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openRestockSheet(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.6,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: UpsertProductModal(
                    Category: '',
                    isRestock: true,
                    existingProduct: p,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openAddVariantSheet(BuildContext ctx, Product parent) async {
    final addedVariant = await showModalBottomSheet<Product>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return UpsertProductModal(
          Category: parent.category.toString(),
          isVariant: true,
          existingProduct: null,
          parentProduct: parent,
        );
      },
    );

    if (addedVariant != null) {
      showDialog(
        context: ctx,
        builder: (context) => CustomNotificationDialog(
          type: 'success',
          title: "Variant Added",
          content: "\"${addedVariant.name}\" has been successfully added to this product.",
          onConfirm: () => Navigator.pop(context),
        ),
      );
    }
  }

  Widget _buildVariantCard(BuildContext ctx, Product v, Product parent,VariantProductProvider variantProductProvider) {
    return InkWell(
      onTap: () => ProductDetailModal.show(ctx, v.id, true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: (v.imagePath != null && v.imagePath!.isNotEmpty)
                    ? DecorationImage(
                  image: FileImage(File(v.imagePath!)),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: (v.imagePath == null || v.imagePath!.isEmpty)
                  ? const Icon(LucideIcons.image, color: AppColor.textSecondary, size: 20)
                  : null,
            ),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: [
                      if (usePack) _buildTag('Pack'),
                      if (usePiece) _buildTag('Piece'),
                    ],
                  ),
                ],
              ),
            ),
            // Edit/Delete
            Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                  onPressed: () => _editVariant(context, v),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash, color: AppColor.errorText),
                  onPressed: () => _deleteVariant(context, parent.id, v.id, variantProductProvider, v.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}