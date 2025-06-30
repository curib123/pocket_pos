import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

class CartListModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _CartListContent(),
    );
  }
}

class _CartListContent extends StatefulWidget {
  const _CartListContent({super.key});

  @override
  State<_CartListContent> createState() => _CartListContentState();
}

class _CartListContentState extends State<_CartListContent> {
  final Map<String, TextEditingController> kiloControllers = {};
  final Map<String, int> quantities = {};
  final TextEditingController cashController = TextEditingController();
  final TextEditingController borrowerController = TextEditingController();

  bool isLoan = false;

  @override
  void dispose() {
    for (var controller in kiloControllers.values) {
      controller.dispose();
    }
    cashController.dispose();
    borrowerController.dispose();
    super.dispose();
  }

  double get buyerCash => double.tryParse(cashController.text) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final loanProvider = context.read<LoanProvider>();
    final cartItems = productProvider.getCartItems();

    double subtotal = 0;
    double costTotal = 0;

    List<Map<String, dynamic>> checkoutItems = [];

    for (var product in cartItems) {
      final quantity = quantities[product.id] ?? 1;
      final isKilo = kiloControllers.containsKey(product.id);
      final double qty = isKilo ? (double.tryParse(kiloControllers[product.id]!.text) ?? 0.0) : quantity.toDouble();
      final productSubtotal = qty * product.retailPrice;
      final productCost = qty * product.costPrice;
      subtotal += productSubtotal;
      costTotal += productCost;

      checkoutItems.add({
        'productId': product.id,
        'quantity': qty,
        'isKilo': isKilo,
      });
    }

    final profit = subtotal - costTotal;
    final change = buyerCash - subtotal;

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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ChoiceChip(label: const Text("Cash"), selected: !isLoan, onSelected: (_) => setState(() => isLoan = false), selectedColor: AppColor.primary.withOpacity(0.15)),
                  ChoiceChip(label: const Text("Loan / Utang"), selected: isLoan, onSelected: (_) => setState(() => isLoan = true), selectedColor: AppColor.secondary.withOpacity(0.15)),
                ],
              ),
              const SizedBox(height: 16),
              ...cartItems.map((product) => _buildProductCard(product)).toList(),
              const SizedBox(height: 16),
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
                      "Change (Sukli): ${change.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: change >= 0 ? AppColor.success : AppColor.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: AppColor.surface,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag, color: AppColor.surface),
                label: const Text("Checkout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final result = productProvider.checkoutCart(
                    cartItems: checkoutItems,
                    isLoan: isLoan,
                    buyerCash: buyerCash,
                    borrowerName: borrowerController.text.trim(),
                    loanProvider: isLoan ? loanProvider : null,
                  );

                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isLoan ? "Loan recorded." : "Checkout successful. Change ${(result['change'] ?? 0.0).toStringAsFixed(2)}")),
                    );
                    productProvider.clearCart();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checkout failed.")));
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final hasImage = product.imageUrl.isNotEmpty && File(product.imageUrl).existsSync();
    final isKilo = kiloControllers.containsKey(product.id);
    final quantity = quantities[product.id] ?? 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                      ? Image.file(File(product.imageUrl), width: 64, height: 64, fit: BoxFit.cover)
                      : Container(
                    width: 64,
                    height: 64,
                    color: AppColor.border,
                    child: const Icon(Icons.image_not_supported, color: AppColor.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(product.retailPrice.toStringAsFixed(2), style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.w600)),
                      Text("Stock: ${product.totalSacks} ${product.unit} / ${product.totalKilos.toStringAsFixed(2)} kg",
                          style: const TextStyle(fontSize: 12, color: AppColor.textSecondary)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(label: const Text("Quantity"), selected: !isKilo, onSelected: (_) {
                  setState(() {
                    kiloControllers.remove(product.id);
                  });
                }),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text("Kilos"), selected: isKilo, onSelected: (_) {
                  setState(() {
                    kiloControllers[product.id] = TextEditingController(text: '0.0');
                  });
                }),
              ],
            ),
            const SizedBox(height: 8),
            isKilo
                ? _buildTextField(kiloControllers[product.id]!, "Enter kilo (kg)", Icons.scale)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                  setState(() {
                    final currentQty = quantities[product.id] ?? 1;
                    if (currentQty > 1) quantities[product.id] = currentQty - 1;
                  });
                }),
                Text('${quantities[product.id] ?? 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                  setState(() {
                    final currentQty = quantities[product.id] ?? 1;
                    quantities[product.id] = currentQty + 1;
                  });
                }),
              ],
            ),
          ],
        ),
      ),
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
        Text(label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: AppColor.textSecondary,
            )),
        Text(value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            )),
      ],
    );
  }
}