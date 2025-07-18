import 'dart:io';
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
    final basePrice = latest.retailPrice;
    final baseCost = latest.costPrice;

    final usePieceMode = usePiece && (!usePack || !isUsePackSwitch);

    price = usePieceMode ? basePrice / perPack : basePrice;
    cost = usePieceMode ? baseCost / perPack : baseCost;

    // stay in packs
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

    final usePack = product.isSoldByPack;
    final usePieces = product.isSoldByPiece;
    final hasImage = product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        File(product.imagePath!).existsSync();

    return SafeArea(
      child: Consumer3<ProductProvider, ProductStockProvider,VariantProductProvider>(
        builder: (context, productProvider, productStockProvider,variantProductProvider, _) {
          return Scaffold(
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              padding: const EdgeInsets.only(bottom: 12,top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image (kept small & neat)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 100,
                          height: 170,
                          child: hasImage
                              ? Image.file(
                            File(product.imagePath!),
                            key: UniqueKey(),
                            fit: BoxFit.fill,
                          )
                              : Container(
                            color: AppColor.border.withOpacity(0.5),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 28,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Info Column
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pack/Pcs toggle if relevant
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                (product.isSoldByPiece && product.isSoldByPack)
                                    ? CustomSwitchPill(
                                  options: ['Pack', 'Pcs'],
                                  selected: isUsePackSwitch ? 'Pack' : 'Pcs',
                                  onSelected: (label) => setState(() {
                                    isUsePackSwitch = label == 'Pack';
                                    final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);
                                    final stock = product.stocks.isNotEmpty ? product.stocks.last : null;
                                    price = stock != null
                                        ? (isUsePackSwitch ? stock.retailPrice : stock.retailPrice / perPack)
                                        : 0;
                                    cost = stock != null
                                        ? (isUsePackSwitch ? stock.costPrice : stock.costPrice / perPack)
                                        : 0;
                                  }),
                                )
                                    : const SizedBox.shrink(), // ← empty widget

                                product.isVariant
                                    ? TextButton.icon(
                                  onPressed: () {
                                    if (widget.ModalAsVariant == true) {
                                      Navigator.pop(context);
                                    } else {
                                      final parentId = variantProductProvider.getParentProductIdFromVariantId(product.id);
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
                                  icon: const Icon(
                                    LucideIcons.cornerUpLeft,
                                    color: Colors.blueGrey,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    "Go Main",
                                    style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: Size.zero,
                                    backgroundColor: Colors.blueGrey.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                                    : IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => CustomConfirmDialog(
                                        title: "Delete Product",
                                        content: "Are you sure you want to delete this product?\nThis action cannot be undone.",
                                        onConfirm: () {
                                          productProvider.deleteProduct(product.id);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  tooltip: "Delete Product",
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColor.error.withOpacity(0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),

                              ],
                            ),
                            if (usePack || usePieces) ...[

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColor.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: _getFontSizeForName(product.name) + 5,
                                      ),
                                    ),
                                  ),
                                  // Add anything else like price or unit here
                                ],
                              ),


                              // Action buttons row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (product.category != null)
                                   _buildTag( product.category!)
                                ],
                              ),
                                SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Builder(
                                      builder: (context) {
                                        final label = '${currency.format(price)} |';
                                        double fontSize;

                                        if (label.length <= 15) {
                                          fontSize = 18;
                                        } else if (label.length <= 25) {
                                          fontSize = 16;
                                        } else {
                                          fontSize = 14;
                                        }

                                        return Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 5), // 🧘 small spacing between text and unit
                                  unitType, // <- make sure this isn't padded internally!
                                ],
                              ),
                              SizedBox(height: 5),
                              // Cost price: smaller, faded with strikethrough
                              Row(
                                children: [
                                  Text(
                                    'Cost Price: ${currency.format(cost)} | ' ,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColor.textSecondary,
                                      fontStyle: FontStyle.italic,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (!product.isSoldByPack && product.isSoldByPiece) ...[
                                    _buildStockLabel('Available Piece: ${formatNumber(product.totalQuantity)}'),
                                  ] else ...[
                                    if (isUsePackSwitch) ...[
                                      _buildStockLabel('Available Pack: ${formatNumber(product.totalQuantity)}'),
                                    ] else ...[
                                      _buildStockLabel('Available Piece: ${formatNumber(product.totalQuantityByPieces)}'),
                                    ],
                                  ],
                                  const SizedBox(width: 12),
                                ],
                              )


                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10,),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Edit',
                          icon: Icons.edit,
                          isFilled: false,
                          borderColor: AppColor.warning,
                          onPressed: () {
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
                                            existingProduct: product,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: CustomButton(
                          borderColor: AppColor.primary,
                          text: 'Restock',
                          icon: Icons.inventory_2,
                          isFilled: false,
                          onPressed: () {
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
                                            isRestock: true,
                                            existingProduct: product,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );

                          },
                        ),
                      ), const SizedBox(width: 5),
                   if(!product.isVariant) ...[
                     Expanded(
                       child: CustomButton(
                         borderColor: AppColor.success,
                         text: 'Add Variant',
                         isFilled: false,
                         onPressed: () async {
                           final addedVariant = await showModalBottomSheet<Product>(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (context) {
                               return UpsertProductModal(
                                 Category: product.category.toString(),
                                 isVariant: true,
                                 existingProduct: null, // optional if you want fresh variant
                                 parentProduct: product,  // ✅ this will be the new param
                               );
                             },
                           );

                           if (addedVariant != null) {
                             showDialog(
                               context: context,
                               builder: (context) => CustomNotificationDialog(
                                 type: 'success',
                                 title: "Variant Added",
                                 content: "\"${addedVariant.name}\" has been successfully added to this product.",
                                 onConfirm: () => Navigator.pop(context),
                               ),
                             );
                           }
                         },
                       ),
                     ),
                   ],

                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product.variants.isEmpty) ...[
                    Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColor.border, width: 1.2),
                          color: AppColor.surface,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.layers,
                              size: 40,
                              color: AppColor.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              !product.isVariant ? 'No Variants Found' : 'This Is a Variant',
                              style: TextStyle(
                                fontSize: context.rf(16),
                                fontWeight: FontWeight.bold,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              !product.isVariant
                                  ? 'Organize this product better by adding variants for sizes, styles, or other options.'
                                  : 'Variants are grouped under a main product. You’re viewing one of them.',
                              style: TextStyle(
                                fontSize: context.rf(13),
                                color: AppColor.textSecondary,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )


                  ],
                  ...product.variants.map((variant) {
                    return InkWell(
                      onTap: () => ProductDetailModal.show(context, variant.id, true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
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
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                image: (variant.imagePath != null && variant.imagePath!.isNotEmpty)
                                    ? DecorationImage(
                                  image: FileImage(File(variant.imagePath!)),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: (variant.imagePath == null || variant.imagePath!.isEmpty)
                                  ? const Icon(LucideIcons.image, color: AppColor.textSecondary, size: 20)
                                  : null,
                            ),

                            // Name + Tag + Quantity
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variant.name,
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
                                      if (usePieces) _buildTag('Piece'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Edit/Delete Buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                                  onPressed: () => _editVariant(context, variant),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash, color: AppColor.errorText),
                                  onPressed: () => _deleteVariant(context, product.id,variant.id,variantProductProvider,variant.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })


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
          fontWeight: FontWeight.w200,
          fontSize: fontSize,
          color: AppColor.textSecondary.withOpacity(0.7),
        ),
      ),
    );
  }

  double _getFontSizeForName(String name) {
    return (18 - (name.length * 0.3)).clamp(10.0, 16.0);
  }


}