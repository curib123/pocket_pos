import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/VariantProductProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomConfimDialog.dart';
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
                          height: 140,
                          child: hasImage
                              ? Image.file(
                            File(product.imagePath!),
                            key: UniqueKey(),
                            fit: BoxFit.cover,
                          )
                              : Container(
                            color: AppColor.border,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 28,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Info Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pack/Pcs toggle if relevant
                            if (product.isSoldByPiece && product.isSoldByPack)
                              CustomSwitchPill(
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
                              ),

                            if (usePack || usePieces) ...[
                              // Product name: big & bold, primary color
                              Text(
                                product.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColor.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),


                              // Action buttons row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (product.category != null)
                                    Expanded(
                                      child: Text(
                                        product.category!,
                                        style: const TextStyle(
                                          color: AppColor.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
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
                                              title: "Go to Parent Product",
                                              content:
                                              "Are you sure you want to view the parent product?\nYou’ll leave this product view.",
                                              onConfirm: () {
                                                Navigator.pop(context);
                                                ProductDetailModal.show(context, parentId, false);
                                              },
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Parent product not found.")),
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
                                      "Main",
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
                                          content:
                                          "Are you sure you want to delete this product?\nThis action cannot be undone.",
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

                              // Retail price: big, bright
                              Text(
                                'Retail: ${currency.format(price)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),

                              // Cost price: smaller, faded with strikethrough
                              Text(
                                'Cost: ${currency.format(cost)} | $unit',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondary,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),

                              // Stock counts: bigger font weight, spaced
                              Row(
                                children: [
                                  Text(
                                    'Pack: ${product.totalQuantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w200,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Piece: ${product.totalQuantityByPieces}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w200,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
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
                          text: 'Restock',
                          icon: Icons.inventory_2,
                          isFilled: false,
                          onPressed: () {
                            // Implement restock logic
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product.variants.isEmpty)
                    Center(
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).width * 0.8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColor.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.layers),
                              const SizedBox(height: 20),
                              Text(
                                'No Variants Available.\nTry adding a new variant.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: context.rf(14),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 10),
                    ...product.variants.map((variant) {
                      return InkWell(
                        onTap: () => ProductDetailModal.show(context, variant.id, true),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              // Variant image or placeholder icon
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


                             // Variant name + unit
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variant.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (usePack || usePieces)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: -4,
                                          children: [
                                            if (usePack) _buildTag('Pack'),
                                            if (usePieces) _buildTag('Piece'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Edit/Delete buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                                    onPressed: () {
                                      // Prevent tap propagation
                                      // TODO: open variant edit modal

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
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash, color: AppColor.errorText),
                                    onPressed: () {
                                      // TODO: confirm & delete variant

                                      showDialog(
                                        context: context,
                                        builder: (context) => CustomConfirmDialog(
                                          title: "Delete Product",
                                          content: "Are you sure you want to delete this product?\nThis action cannot be undone.",
                                          onConfirm: () {
                                            variantProductProvider.deleteVariant(product.id, variant.id);
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
                      );

                    }),
                  ],

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
}
