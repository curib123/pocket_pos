import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomBatchDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomSwitchPill.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/Modal/AddProductModal.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';
import 'package:provider/provider.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/View/Components/ResponsiveText.dart';

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
  final TextEditingController inputController = TextEditingController();
  int quantity = 0;
  bool useTextField = false;

  @override
  void initState() {
    super.initState();

    inputController.addListener(() {
      final parsed = int.tryParse(inputController.text);
      final maxQty = widget.product.totalQuantity.toInt();

      if (parsed != null && parsed > maxQty) {
        inputController.text = maxQty.toString();
        inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: inputController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasImage = product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();
    final currency = context.read<CurrencyProvider>().currencyFormat;

    return SafeArea(
      child: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image and Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImage
                          ? Image.file(
                        File(product.imageUrl),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_outlined, color: AppColor.error),
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
                              )
                            ],
                          ),
                          if (product.category.isNotEmpty)
                            Text(
                              product.category,
                              style: const TextStyle(
                                color: AppColor.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Retail: ${currency.format(product.retailPrice)} | ${product.unit}',
                            style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Cost: ${currency.format(product.costPrice)} | ${product.unit}',
                            style: const TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            product.description,
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Edit',
                        icon: Icons.edit,
                        onPressed: () {
                          Future.delayed(Duration.zero, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                  child: FractionallySizedBox(
                                    heightFactor: 0.8,
                                    child: ProductModalForm(
                                      existingProduct: product,
                                      category: '',
                                    ),
                                  ),
                                );
                              },
                            );
                          });
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
                          Future.delayed(Duration.zero, () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                  child: FractionallySizedBox(
                                    heightFactor: 0.8,
                                    child: ProductModalForm(
                                      existingProduct: product,
                                      category: '',
                                      isRestock: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Total Stock and Batches
                if (product.batches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Stock Batches: ${product.totalQuantity} ${product.unit}',
                    style: TextStyle(
                      fontSize: context.rf(14),
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary,
                      fontStyle: FontStyle.italic, // 👈 Add this line
                    ),
                  ),

                  const SizedBox(height: 4),
                ],

                if (product.batches.isNotEmpty)
                  ...product.batches.map((batch) {
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
                              '${batch.quantity} ${product.unit} • ${DateFormat.yMMMd().format(batch.createdAt)}',
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
                                    initialQty: batch.quantity,
                                    onConfirm: (qty) {
                                      productProvider.updateBatchQty(
                                        productName: product.name,
                                        batchId: batch.id,
                                        newQuantity: qty,
                                      );
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
                                        productProvider.deleteBatchByProductName(product.name, batch.id);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),

                if (product.batches.isEmpty) ...[
                  const SizedBox(height: 20),
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
                          Icon(
                            LucideIcons.box,
                            size: 48,
                            color: Colors.grey.withOpacity(0.7),
                          ),
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
                ],


                // Input / Stepper / Buttons - Only if batches exist
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
                          icon: const Icon(Icons.remove_circle_outline, color: AppColor.primary),
                          onPressed: () {
                            if (quantity > 0) setState(() => quantity--);
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColor.primary),
                          onPressed: () {
                            if (quantity < product.totalQuantity) {
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
                          onPressed: () {
                            final inputQty = int.tryParse(inputController.text) ?? 0;
                            final maxQty = product.totalQuantity.toInt();
                            final finalQty = useTextField ? inputQty : quantity;

                            if (finalQty <= 0) {
                              SnackbarService.showWarning( 'Quantity must be greater than 0');
                              return;
                            }
                            if (finalQty > maxQty) {
                              SnackbarService.showError('Quantity exceeds available stock');
                              return;
                            }

                            // Add to cart logic
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          text: 'Proceed',
                          icon: Icons.check_circle_outline,
                          isFilled: true,
                          onPressed: () {
                            final inputQty = int.tryParse(inputController.text) ?? 0;
                            final maxQty = product.totalQuantity.toInt();
                            final finalQty = useTextField ? inputQty : quantity;

                            if (finalQty <= 0) {
                              SnackbarService.showWarning( 'Quantity must be greater than 0');
                              return;
                            }
                            if (finalQty > maxQty) {
                              SnackbarService.showError('Quantity exceeds available stock');
                              return;
                            }

                            // Proceed logic
                          },
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
