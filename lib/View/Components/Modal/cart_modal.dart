import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Alert/custom_confirm_dialog.dart';
import 'package:paninda/View/Components/Alert/show_quantity_edit.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';
import 'package:paninda/View_Model/CurrencyProvider.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

class CartModal {
  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ProductProfileContent(product: product),
    );
  }
}

class _ProductProfileContent extends StatefulWidget {
  final Product product;
  const _ProductProfileContent({super.key, required this.product});

  @override
  State<_ProductProfileContent> createState() => _ProductProfileContentState();
}

class _ProductProfileContentState extends State<_ProductProfileContent> {
  String selectedMode = 'sacks'; // initial state
  TextEditingController kiloController = TextEditingController();
  int quantity = 0;
  double kiloQuantity = 0.0;


  @override
  void dispose() {
    kiloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    final product = widget.product;
    final hasImage = product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();
    final dateFormat = DateFormat('MMM d, yyyy');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 6,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Product Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImage
                        ? Image.file(File(product.imageUrl), width: 100, height: 100, fit: BoxFit.cover)
                        : Container(
                      width: 100,
                      height: 100,
                      color: AppColor.border,
                      child: const Icon(Icons.image_not_supported, size: 32, color: AppColor.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: AppColor.errorText),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => CustomConfirmDialog(
                                    icon: Icons.delete_forever,
                                    iconColor: Colors.redAccent,
                                    title: "Are You Sure?",
                                    content: "Deleting this product is permanent and cannot be undone.",
                                    cancelText: "Go Back",
                                    confirmText: "Delete Product",
                                    onConfirm: () {
                                      provider.removeProduct(product.id);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(currencyFormat.format(product.retailPrice),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primary)),
                        const SizedBox(height: 6),
                        Text(
                          'Cost: ${currencyFormat.format(product.costPrice)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColor.textSecondary,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Description: ${product.description}",
                            style: const TextStyle(fontSize: 14, color: AppColor.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Edit/Restock Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 20, color: AppColor.surface),
                      label: const Text("Edit Product"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        AddProductModal.show(context, isEdit: true, product: product);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.inventory_2_rounded, size: 20, color: AppColor.surface),
                      label: const Text("Restock"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColor.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        AddProductModal.show(context, isStock: true, product: product);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Batch List
              if (product.batches.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Stocks:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                      const SizedBox(height: 5),
                      const Text(
                        "Restocking on the same day will automatically combine with the existing stock for that date.",
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.batches.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final batch = product.batches[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Qty: ${batch.quantity} ${product.unit}  •  ${batch.kiloQuantity.toStringAsFixed(2)} kg",
                                  style: const TextStyle(fontSize: 14, color: AppColor.textSecondary)),
                              const SizedBox(height: 5),
                              Text(dateFormat.format(batch.date), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.edit, color: AppColor.primary),
                                onPressed: () {
                                  showQuantityEditDialog(
                                    context: context,
                                    title: 'Update Quantity',
                                    initialQuantity: batch.quantity,
                                    initialKiloQuantity: batch.kiloQuantity,
                                    onConfirm: (newQty, newKiloQty) {
                                      provider.updateProductQuantityManually(product.id, newQty, newKiloQty);
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.delete, color: AppColor.errorText),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomConfirmDialog(
                                      icon: Icons.delete_forever,
                                      iconColor: Colors.redAccent,
                                      title: "Are You Sure?",
                                      content: "Deleting this Batch is permanent and cannot be undone.",
                                      cancelText: "Go Back",
                                      confirmText: "Confirm Delete",
                                      onConfirm: () {
                                        provider.removeBatchFromProduct(productId: product.id, batchDate: batch.date);
                                      },
                                    ),
                                  );
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Quantity Stepper + Kilo Input with Modern UX Toggle (Borderless, Soft UI)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Soft Toggle Navigation
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton('Qty', selectedMode == 'Qty', () {
                          setState(() => selectedMode = 'Qty');
                        }),
                        const SizedBox(width: 8),
                        _buildToggleButton('Kilo', selectedMode == 'kilo', () {
                          setState(() => selectedMode = 'kilo');
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quantity or Kilo Input (Only One Shown at a Time)
                  if (selectedMode == 'Qty') ...[
                    const Text("Quantity (Pcs)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (quantity > 0) setState(() => quantity--);
                          },
                          icon: const Icon(Icons.remove_circle_outline, color: AppColor.primary, size: 28),
                          splashRadius: 24,
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColor.primary),
                        ),
                        IconButton(
                          onPressed: () {
                            if (product.totalSacks > quantity) {
                              setState(() => quantity++);
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, color: AppColor.primary, size: 28),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ],

                  if (selectedMode == 'kilo') ...[
                    const Text("Kilo Quantity (kg)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: kiloController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: "Enter kilo (kg)",
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            kiloQuantity = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Text(
                    "Switch between Qty or kilos to adjust quantity.",
                    style: TextStyle(color: AppColor.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),


              const SizedBox(height: 24),

// Add to Cart with Reminder
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.primary.withOpacity(0.4)),
                    ),
                    child: const Text(
                      "Reminder: Review your cart and proceed to checkout when you're ready.",
                      style: TextStyle(color: AppColor.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                    label: const Text("Add to Cart",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColor.surface)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                    ),
                    onPressed: () {
                      provider.addToCart(product, quantity, kiloQuantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Added $quantity ${product.unit}(s) & $kiloQuantity kg to cart")),
                      );
                    },
                  ),
                ],
              ),


              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary : AppColor.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColor.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

}
