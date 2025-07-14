// ✅ FINALIZED PRODUCT DETAIL MODAL

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Helper/Enums/enum.dart';
import 'package:mobile_pos_inventory/Model/batch_model.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Provider/BatchProvider.dart';
import 'package:mobile_pos_inventory/Provider/CartProvider.dart';
import 'package:mobile_pos_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomBatchDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomSwitchPill.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/Modal/CartModal.dart';
import 'package:mobile_pos_inventory/View/Components/ResponsiveText.dart';
import 'package:mobile_pos_inventory/View/Components/Modal/AddProductModal.dart';
import 'package:provider/provider.dart';

class ProductDetailModal {
  static void show(BuildContext context, Product product) {
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
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: _ProductDetailContent(product: product),
          ),
        );
      },
    );
  }
}

class _ProductDetailContent extends StatefulWidget {
  final Product product;
  const _ProductDetailContent({required this.product});

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {
  bool usePack = true;
  bool useTextField = false;
  double price = 0;
  String unit = '';
  int quantity = 1;
  final TextEditingController inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    usePack = widget.product.isPack;
    unit = usePack ? widget.product.unit : UnitType.pcs.label;
    price = usePack
        ? widget.product.packItemsRetail
        : (widget.product.packItems > 0
        ? widget.product.packItemsRetail / widget.product.packItems
        : 0);
  }

  void _addToCart(CartProvider cartProvider) {
    final inputQty = int.tryParse(inputController.text) ?? 0;
    final maxQty = usePack ? widget.product.totalQuantity.toInt() : widget.product.subQuantity.toInt();
    final finalQty = useTextField ? inputQty : quantity;

    if (finalQty <= 0) {
      _showWarning('Invalid Quantity', 'The quantity must be more than 0 to proceed.');
      return;
    }

    if (finalQty > maxQty) {
      _showWarning('Stock Limit Exceeded', 'The quantity exceeds available stock.');
      return;
    }
    final productToCart = Product(
      id: widget.product.id,
      name: widget.product.name,
      unit: unit,
      batches: [
        Batch(
          id: DateTime.now().toIso8601String(),
          quantity: usePack ? finalQty.toDouble() : 0.0,
          subQuantity: !usePack ? finalQty.toDouble() : 0.0,
          createdAt: DateTime.now(),
        ),
      ],
      description: widget.product.description,
      imageUrl: widget.product.imageUrl,
      category: widget.product.category,
      lastModified: DateTime.now(),
      deletedAt: widget.product.deletedAt,
      defaultCost: usePack ? widget.product.packItemsCost : widget.product.costPerItem,
      defaultRetail: price,
      isPack: usePack,
      packItems: widget.product.packItems,
      packItemsCost: widget.product.packItemsCost,
      packItemsRetail: widget.product.packItemsRetail,
      profitMargin: widget.product.profitMargin,
    );


    cartProvider.addToCart(productToCart);
    Navigator.pop(context);
  }

  void _proceedToCart(CartProvider cartProvider) {
    _addToCart(cartProvider);
    Future.delayed(Duration.zero, () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: const CartScreen(),
          ),
        ),
      );
    });
  }

  void _showWarning(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        type: "warning",
        title: title,
        content: message,
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasImage = product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();
    final currency = context.read<CurrencyProvider>().currencyFormat;

    return SafeArea(
      child: Consumer3<ProductProvider, CartProvider, BatchProvider>(
        builder: (context, productProvider, cartProvider, batchProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.isPack)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: CustomSwitchPill(
                          options: ['Pack', 'Pieces'],
                          selected: usePack ? 'Pack' : 'Pieces',
                          onSelected: (label) => setState(() {
                            usePack = label == 'Pack';
                            unit = usePack ? product.unit : UnitType.pcs.label;
                            price = usePack
                                ? product.packItemsRetail
                                : (product.packItems > 0
                                ? product.packItemsRetail / product.packItems
                                : 0);
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImage
                          ? Image.file(File(product.imageUrl), key: UniqueKey(), width: 100, height: 100, fit: BoxFit.cover)
                          : Container(
                        width: 100,
                        height: 100,
                        color: AppColor.border,
                        child: const Icon(Icons.image_not_supported, size: 32, color: AppColor.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (product.category.isNotEmpty)
                            Text(product.category, style: const TextStyle(color: AppColor.textSecondary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Retail: ${currency.format(price)} | $unit', style: const TextStyle(color: AppColor.primary)),
                          Text(
                            'Cost: ${currency.format(usePack ? product.packItemsCost : product.costPerItem)} | $unit',
                            style: const TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(product.description, style: const TextStyle(color: AppColor.textSecondary, fontSize: 13)),
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
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.8,
                              child: ProductModalForm(existingProduct: product, category: ''),
                            ),
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
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.8,
                              child: ProductModalForm(existingProduct: product, category: '', isRestock: true),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (product.batches.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Batches: ${usePack ? product.totalQuantity : product.subQuantity} $unit',
                        style: TextStyle(
                          fontSize: context.rf(14),
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...product.batches.map((batch) {
                        final stock = usePack ? batch.quantity : (batch.subQuantity ?? 0);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$stock $unit • ${DateFormat.yMMMd().format(batch.createdAt)}',
                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                                    onPressed: () {
                                      showChangeBatchQtyDialog(
                                        context: context,
                                        initialQty: stock,
                                        onConfirm: (qty) {
                                          usePack
                                              ? batchProvider.updateBatchQuantity(product.name, batch.id, qty)
                                              : batchProvider.updateSubQuantity(product.name, batch.id, qty);
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash, color: AppColor.errorText),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => CustomConfirmDialog(
                                          title: "Delete Batch",
                                          content: "Are you sure you want to delete this batch?\nThis action cannot be undone.",
                                          onConfirm: () {
                                            usePack
                                                ? batchProvider.deleteBatch(product.name, batch.id)
                                                : batchProvider.deleteSubQuantity(product.name, batch.id);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  )
                else
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.box, size: 48, color: Colors.grey.withOpacity(0.7)),
                          const SizedBox(height: 12),
                          Text(
                            'No Batches Available',
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: context.rf(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try restocking this product to add batches.',
                            style: TextStyle(
                              color: AppColor.textSecondary.withOpacity(0.8),
                              fontSize: context.rf(12),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (product.batches.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: CustomSwitchPill(
                      options: ['Stepper', 'Input'],
                      selected: useTextField ? 'Input' : 'Stepper',
                      onSelected: (label) => setState(() => useTextField = label == 'Input'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  useTextField
                      ? CustomTextField(
                    label: 'Enter Quantity',
                    controller: inputController,
                    keyboardType: TextInputType.number,
                    hintText: 'e.g. 15',
                  )
                      : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColor.primary, size: 30),
                          onPressed: () => setState(() => quantity = quantity > 0 ? quantity - 1 : 0),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColor.primary, size: 30),
                          onPressed: () {
                            final maxQty = usePack ? product.totalQuantity : product.subQuantity;
                            if (quantity < maxQty) {
                              setState(() => quantity++);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Add to Cart',
                          icon: Icons.shopping_cart_outlined,
                          isFilled: false,
                          onPressed: () => _addToCart(cartProvider),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          text: 'Proceed',
                          icon: Icons.check_circle_outline,
                          isFilled: true,
                          onPressed: () => _proceedToCart(cartProvider),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
