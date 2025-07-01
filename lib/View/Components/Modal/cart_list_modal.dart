import 'dart:io';
import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
// Keep all your imports the same — no change to logic.

class CartListModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85, // 85% of the screen height
        child: const _CartListContent(),
      ),
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
  void initState() {
    super.initState();
    final cartItems = context.read<ProductProvider>().getCartItems();
    for (var entry in cartItems.entries) {
      quantities[entry.key.id] = entry.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final loanProvider = context.read<LoanProvider>();
    final cartItems = productProvider.getCartItems();

    double subtotal = 0;
    double costTotal = 0;

    List<Map<String, dynamic>> checkoutItems = [];

    for (var entry in cartItems.entries) {
      final product = entry.key;
      final quantity = quantities[product.id] ?? entry.value;
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColor.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              /// Payment Mode
              Center(
                child: Wrap(
                  spacing: 12,
                  children: [
                    ChoiceChip(
                      label: const Text("Cash"),
                      selected: !isLoan,
                      onSelected: (_) => setState(() => isLoan = false),
                      selectedColor: AppColor.primary.withOpacity(0.15),
                    ),
                    ChoiceChip(
                      label: const Text("Loan / Utang"),
                      selected: isLoan,
                      onSelected: (_) => setState(() => isLoan = true),
                      selectedColor: AppColor.secondary.withOpacity(0.15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Cart Products
              ...cartItems.keys.map((product) => _buildProductCard(product)).toList(),

              const SizedBox(height: 24),

              /// Payment input field
              if (!isLoan)
                _buildTextField(cashController, "Enter Cash", Icons.payments)
              else
                _buildTextField(borrowerController, "Borrower's Name", Icons.person),

              if (!isLoan)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (change >= 0 ? AppColor.success.withOpacity(0.1) : AppColor.error.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Change (Sukli):",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        Text(
                          "${change.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: change >= 0 ? AppColor.success : AppColor.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              const SizedBox(height: 24),

              /// Summary Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColor.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _buildPriceRow("Subtotal", subtotal, AppColor.secondary),
                      const SizedBox(height: 8),
                      _buildPriceRow("Cost", costTotal, AppColor.warning),
                      const Divider(height: 24),
                      _buildPriceRow("Profit", profit, profit >= 0 ? AppColor.accent : AppColor.error, isBold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Checkout Button
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_bag,color: AppColor.surface,),
                label: const Text("Checkout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                  onPressed: () async {
                    final result = await productProvider.checkoutCart(
                      cartItems: checkoutItems,
                      isLoan: isLoan,
                      buyerCash: buyerCash,
                      borrowerName: borrowerController.text.trim(),
                      loanProvider: isLoan ? loanProvider : null,
                    );

                    if (result != null) {
                      final profit = (result['profit'] ?? 0.0) as double;
                      final change = (result['change'] ?? 0.0) as double;

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isLoan
                                ? "Loan recorded. Profit ₱${profit.toStringAsFixed(2)}"
                                : "Checkout successful. Change ₱${change.toStringAsFixed(2)} | Profit ₱${profit.toStringAsFixed(2)}",
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Checkout failed.")),
                      );
                    }
                  }

              ),

              const SizedBox(height: 12),

              CustomButton(
                color: AppColor.error,
                icon: Icons.exit_to_app_rounded,
                label: "Exit",
                onPressed: () => Navigator.pop(context),
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

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Image & Info Row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImage
                        ? Image.file(
                      File(product.imageUrl),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 56,
                      height: 56,
                      color: AppColor.border,
                      child: const Icon(Icons.image_not_supported, color: AppColor.textSecondary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            )),
                        const SizedBox(height: 4),
                        Text("${product.retailPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          "Stock: ${product.totalSacks} ${product.unit} / ${product.totalKilos.toStringAsFixed(2)} kg",
                          style: const TextStyle(fontSize: 12, color: AppColor.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// Unit selector
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("Quantity", style: TextStyle(fontSize: 13)),
                    selected: !isKilo,
                    onSelected: (_) => setState(() => kiloControllers.remove(product.id)),
                    selectedColor: AppColor.primary.withOpacity(0.15),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: !isKilo ? AppColor.primary : AppColor.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Kilos", style: TextStyle(fontSize: 13)),
                    selected: isKilo,
                    onSelected: (_) => setState(() {
                      kiloControllers[product.id] = TextEditingController(text: '0.0');
                    }),
                    selectedColor: AppColor.primary.withOpacity(0.15),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isKilo ? AppColor.primary : AppColor.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// Quantity control or input
              isKilo
                  ? _buildTextField(kiloControllers[product.id]!, "Enter kilo (kg)", Icons.scale)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    color: AppColor.error,
                    onPressed: () {
                      setState(() {
                        final currentQty = quantities[product.id] ?? 1;
                        if (currentQty > 1) quantities[product.id] = currentQty - 1;
                      });
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$quantity',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: AppColor.primary,
                    onPressed: () {
                      setState(() {
                        final currentQty = quantities[product.id] ?? 1;
                        quantities[product.id] = currentQty + 1;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        /// ❌ Remove icon (top-right)
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                quantities.remove(product.id);
                kiloControllers.remove(product.id);
                context.read<ProductProvider>().removeFromCart(product);
              });
            },
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColor.error,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );

  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: AppColor.textSecondary)),
        Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}
