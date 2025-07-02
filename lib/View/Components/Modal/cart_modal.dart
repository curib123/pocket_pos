import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';
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
  int quantity = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();
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
              // Handle Bar
              Container(
                width: 48,
                height: 6,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Product Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₱${product.retailPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Cost: ₱${product.costPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColor.textSecondary,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Description: ${product.description}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Edit and Restock Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon:  Icon(Icons.edit, size: 20,color: AppColor.surface,),
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
                      icon:  Icon(Icons.inventory_2_rounded, size: 20,color: AppColor.surface,),
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

              // Batches Section
              if (product.batches.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Stocks:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
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
                          Text(
                            "Qty: ${batch.quantity.toStringAsFixed(0)} ${product.unit}\nKg: ${batch.kiloQuantity.toStringAsFixed(2)} kg",
                            style: const TextStyle(fontSize: 14, color: AppColor.textSecondary),
                          ),
                          Text(
                            dateFormat.format(batch.date),
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Quantity Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 0) setState(() => quantity--);
                    },
                    icon: const Icon(Icons.remove_circle, color: AppColor.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.primary),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => product.totalSacks > quantity ? quantity++ : null),
                    icon: const Icon(Icons.add_circle, color: AppColor.primary),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add to Cart Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                label: const Text(
                  "Add to Cart",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColor.surface),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                onPressed: () {
                  provider.addToCart(product, quantity);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Added $quantity ${product.unit}(s) to cart")),
                  );
                },
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
