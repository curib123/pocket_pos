// ✅ FINALIZED PRODUCT DETAIL MODAL
import 'dart:io';
import 'dart:math';
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
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomSwitchPill.dart';
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
  double price = 0;
  String unit = '';

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
                          ? Image.file(File(product.imageUrl), width: 100, height: 100, fit: BoxFit.cover)
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
                          Text('Cost: ${currency.format(usePack ? product.packItemsCost : product.costPerItem)} | $unit',
                              style: const TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough)),
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
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.8,
                            child: ProductModalForm(existingProduct: product, category: ''),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: CustomButton(
                        text: 'Restock',
                        icon: Icons.inventory_2,
                        isFilled: false,
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.8,
                            child: ProductModalForm(existingProduct: product, category: '', isRestock: true),
                          ),
                        ),
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
                            fontStyle: FontStyle.italic),
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
                                          content:
                                          "Are you sure you want to delete this batch?\nThis action cannot be undone.",
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
                          Text('No Batches Available',
                              style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: context.rf(14),
                                  fontWeight: FontWeight.w600)),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
