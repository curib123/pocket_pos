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
  bool isUsePackSwitch = true;
  bool useTextField = false;
  int quantity = 1;
  double price = 0;
  double cost = 0;
  String unit = '';
  final TextEditingController inputController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final product = context.read<ProductProvider>().getProductById(widget.productId);
    if (product != null) {
      final perPack = product.piecesPerPack ?? 1;
      final latest = product.stocks.isNotEmpty ? product.stocks.last : null;
      final usePack = product.isSoldByPack;

      unit = product.unit ?? "unit";

      if (latest != null) {
        price = usePack ? latest.retailPrice : latest.retailPrice / perPack;
        cost = usePack ? latest.costPrice : latest.costPrice / perPack;
      }
    }
  }

  Widget get unitType {
    return Row(
      children: [
        if (isUsePackSwitch) _buildTag('Pack') else _buildTag('Piece'),
      ],
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
                   CustomSwitchPill(
                      options: ['Stepper', 'Input'],
                      selected: useTextField ? 'Input' : 'Stepper',
                      onSelected: (label) =>
                          setState(() => useTextField = label == 'Input'),
                    ),
                    useTextField
                        ? CustomTextField(
                      label: 'Enter Quantity',
                      controller: inputController,
                      keyboardType: TextInputType.number,
                      hintText: 'e.g. 15',
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 30, color: AppColor.primary),
                          onPressed: () =>
                              setState(() => quantity = quantity > 0 ? quantity - 1 : 0),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 30, color: AppColor.primary),
                          onPressed: () {
                            final maxQty = isUsePackSwitch
                                ? product.totalQuantity
                                : product.looseStock?.remainingPieces ?? 0;
                            if (quantity < maxQty) {
                              setState(() => quantity++);
                            }
                          },
                        ),
                      ],
                    ),
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
            appBar: AppBar(
              title :  // 🟢 Switch
              CustomSwitchPill(
                options: ['Pack', 'Pcs'],
                selected: isUsePackSwitch ? 'Pack' : 'Pcs',
                onSelected: (label) => setState(() {
                  isUsePackSwitch = label == 'Pack';

                  final perPack = (product.piecesPerPack ?? 1).clamp(1, double.infinity);
                  if (product.stocks.isNotEmpty) {
                    final latestStock = product.stocks.last;
                    price = isUsePackSwitch
                        ? latestStock.retailPrice
                        : latestStock.retailPrice / perPack;
                    cost = isUsePackSwitch
                        ? latestStock.costPrice
                        : latestStock.costPrice / perPack;
                  } else {
                    price = 0;
                    cost = 0;
                  }
                }),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColor.primary),
              ),
              centerTitle: true,
            ),

            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12,top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: hasImage
                            ? Image.file(
                          File(product.imagePath!),
                          key: UniqueKey(),
                          fit: BoxFit.fill, // 👈 THIS shows full image without cropping
                        )
                            : Container(
                          color: AppColor.border,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 32,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            if (usePack && usePieces)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start, // Ensures better vertical alignment
                                children: [
                                  // 🔹 Left: Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColor.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔹 Right: Button
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
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: Size.zero,
                                      backgroundColor: Colors.blueGrey.withOpacity(0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                                      size: 20,
                                    ),
                                    tooltip: "Delete Product",
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColor.error.withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),

                            if (product.category != null)
                              Text(
                                product.category!,
                                style: const TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            Row(
                              children: [
                                Text(
                                  'Retail: ${currency.format(price)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('|', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                unitType,
                              ],
                            ),
                            Text(
                              'Cost: ${currency.format(cost)} | $unit',
                              style: const TextStyle(
                                color: AppColor.textSecondary,
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  ' ${isUsePackSwitch ? product.totalQuantity : (product.looseStock?.remainingPieces ?? 0)} ',
                                  style: TextStyle(
                                    fontSize: context.rf(14),
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                unitType,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No Variants Available.\nTry adding a new variant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: context.rf(13),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 10),
                    ...product.variants.map((variant) {
                      return InkWell(
                        onTap: () {
                          // TODO: Handle variant tile click — maybe open a detail modal or go to edit screen
                          ProductDetailModal.show(context, variant.id,true);
                        },
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
                              // Image or placeholder
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  image: variant.imagePath != null && variant.imagePath!.isNotEmpty
                                      ? DecorationImage(
                                    image: FileImage(File(variant.imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: variant.imagePath == null || variant.imagePath!.isEmpty
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
