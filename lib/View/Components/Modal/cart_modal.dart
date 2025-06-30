import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
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
      builder: (context) => _CartContent(product: product),
    );
  }
}

class _CartContent extends StatefulWidget {
  final Product product;
  const _CartContent({super.key, required this.product});

  @override
  State<_CartContent> createState() => _CartContentState();
}

class _CartContentState extends State<_CartContent> {
  int quantity = 1;
  bool isKilo = false;
  bool isLoan = false;

  final TextEditingController kiloController = TextEditingController(text: '0.0');
  final TextEditingController cashController = TextEditingController();
  final TextEditingController borrowerController = TextEditingController();

  double get inputKilos => double.tryParse(kiloController.text) ?? 0.0;
  double get buyerCash => double.tryParse(cashController.text) ?? 0.0;
  double get subtotal => (isKilo ? inputKilos : quantity.toDouble()) * widget.product.retailPrice;
  double get costTotal => (isKilo ? inputKilos : quantity.toDouble()) * widget.product.costPrice;
  double get profit => subtotal - costTotal;

  void _increment() {
    if (quantity < widget.product.totalSacks.floor()) {
      setState(() => quantity++);
    }
  }

  void _decrement() {
    if (quantity > 1) {
      setState(() => quantity--);
    }
  }

  @override
  void dispose() {
    kiloController.dispose();
    cashController.dispose();
    borrowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();
    final loanProvider = context.read<LoanProvider>();
    final hasImage = widget.product.imageUrl.isNotEmpty && File(widget.product.imageUrl).existsSync();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              // Product Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: hasImage
                            ? Image.file(File(widget.product.imageUrl), width: 72, height: 72, fit: BoxFit.cover)
                            : Container(
                          width: 72,
                          height: 72,
                          color: AppColor.border,
                          child: const Icon(Icons.image_not_supported, color: AppColor.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              widget.product.retailPrice.toStringAsFixed(2),
                              style: TextStyle(
                                color: AppColor.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Stock: ${isKilo ? widget.product.totalKilos.toStringAsFixed(2) + ' kg' : '${widget.product.totalSacks.toStringAsFixed(0)} ${widget.product.unit}'}",
                              style: const TextStyle(fontSize: 13, color: AppColor.textSecondary),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Mode Selection Chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _chip("Quantity", !isKilo, () => setState(() => isKilo = false)),
                  _chip("Kilos", isKilo, () => setState(() => isKilo = true)),
                  _chip("Cash", !isLoan, () => setState(() => isLoan = false), color: AppColor.secondary),
                  _chip("Loan / Utang", isLoan, () => setState(() => isLoan = true), color: AppColor.secondary),
                ],
              ),

              const SizedBox(height: 20),

              // Quantity / Kilo Input
              isKilo
                  ? _buildTextField(kiloController, "Enter kilo (kg)", Icons.scale)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _decrement),
                  Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _increment),
                ],
              ),

              const SizedBox(height: 16),

              // Payment Method Input
              if (!isLoan)
                _buildTextField(cashController, "Enter Cash", Icons.payments)
              else
                _buildTextField(borrowerController, "Borrower's Name", Icons.person),

              if (!isLoan)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Change (Sukli): ${(buyerCash - subtotal).toStringAsFixed(2)}",
                      style: TextStyle(
                        color: buyerCash >= subtotal ? AppColor.success : AppColor.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Price Summary
              Card(
                color: AppColor.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _buildPriceRow("Subtotal", subtotal, AppColor.secondary),
                      _buildPriceRow("Cost", costTotal, AppColor.warning),
                      const Divider(),
                      _buildPriceRow("Profit", profit, profit >= 0 ? AppColor.accent : AppColor.error, isBold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Add to Cart Button
              _styledButton(
                label: "Add to Cart",
                icon: Icons.add_shopping_cart,
                color: AppColor.primary,
                onPressed: () {
                  provider.addToCart(widget.product);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart")));
                },
              ),

              const SizedBox(height: 12),

              // Checkout Button
              _styledButton(
                label: "Checkout",
                icon: Icons.shopping_bag,
                color: AppColor.secondary,
                onPressed: () {
                  final qty = isKilo ? inputKilos : quantity.toDouble();
                  final available = isKilo ? widget.product.totalKilos : widget.product.totalSacks;

                  if (qty <= 0 || qty > available) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid or insufficient stock.")));
                    return;
                  }

                  final result = provider.checkoutCart(
                    cartItems: [
                      {
                        'productId': widget.product.id,
                        'quantity': qty,
                        'isKilo': isKilo,
                      }
                    ],
                    isLoan: isLoan,
                    buyerCash: buyerCash,
                    borrowerName: borrowerController.text.trim(),
                    loanProvider: isLoan ? loanProvider : null,
                  );

                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isLoan
                              ? "Loan recorded."
                              : "Checkout successful. Change ${(result['change'] ?? 0.0).toStringAsFixed(2)}",
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checkout failed.")));
                  }
                },
              ),

              const SizedBox(height: 12),

              // Add to Cart Button
              _styledButton(
                label: "Exit",
                icon: Icons.exit_to_app_rounded,
                color: AppColor.error,
                onPressed: () {

                  Navigator.pop(context);

                },
              ),


              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color color = AppColor.primary}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.15),
      backgroundColor: AppColor.surface,
      labelStyle: TextStyle(color: selected ? color : AppColor.textSecondary),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColor.textSecondary,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _styledButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: AppColor.surface),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}
