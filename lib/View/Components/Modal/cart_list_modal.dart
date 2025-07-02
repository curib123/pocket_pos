import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    double finalTotalPrice = 0;
    double costTotal = 0;

    List<Map<String, dynamic>> checkoutItems = [];

    for (var entry in cartItems.entries) {
      final product = entry.key;
      final quantity = quantities[product.id] ?? entry.value;
      final isKilo = kiloControllers.containsKey(product.id);
      final double qty = isKilo ? (double.tryParse(kiloControllers[product.id]!.text) ?? 0.0) : quantity.toDouble();
      final productTotalPrice = qty * product.retailPrice;
      final productCost = qty * product.costPrice;
      finalTotalPrice += productTotalPrice;
      costTotal += productCost;

      checkoutItems.add({
        'productId': product.id,
        'quantity': qty,
        'isKilo': isKilo,
      });
    }

    final profit = finalTotalPrice - costTotal;
    final change = buyerCash - finalTotalPrice;

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
                      _buildPriceRow("Final Total ", finalTotalPrice, AppColor.secondary),
                      const SizedBox(height: 8),
                      _buildPriceRow("Total Cost", costTotal, AppColor.warning),
                      const Divider(height: 24),
                      _buildPriceRow("Profit", profit, profit >= 0 ? AppColor.accent : AppColor.error, isBold: true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              /// Checkout Button
              ElevatedButton.icon(
                icon: const Icon(
                  LucideIcons.shoppingBag,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "Checkout",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: AppColor.primary.withOpacity(0.2),
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
                    productProvider.clearCart();
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
                },
              ),

              const SizedBox(height: 12),

              /// Exit Button
              ElevatedButton.icon(
                icon: const Icon(
                  LucideIcons.logOut,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "Exit",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  shadowColor: AppColor.error.withOpacity(0.2),
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const SizedBox(height: 10),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 400;
        final isLarge = screenWidth > 600;
        double baseFont(double size) => isSmall ? size * 0.9 : isLarge ? size * 1.1 : size;

        return Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Top Row: Image + Info + Chips
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: hasImage
                            ? Image.file(
                          File(product.imageUrl),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 48,
                          height: 48,
                          color: AppColor.border,
                          child: const Icon(LucideIcons.imageOff, color: AppColor.textSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),

                      /// Info + Chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: baseFont(14),
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              "₱${product.retailPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: baseFont(13),
                                color: AppColor.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.box, size: 13, color: AppColor.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "${product.totalSacks} ${product.unit} / ${product.totalKilos.toStringAsFixed(2)} kg",
                                    style: TextStyle(
                                      fontSize: baseFont(11),
                                      color: AppColor.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: Text("Qty", style: TextStyle(fontSize: baseFont(11))),
                                  selected: !isKilo,
                                  onSelected: (_) => setState(() => kiloControllers.remove(product.id)),
                                  selectedColor: AppColor.primary.withOpacity(0.1),
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: !isKilo ? AppColor.primary : AppColor.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text("Kg", style: TextStyle(fontSize: baseFont(11))),
                                  selected: isKilo,
                                  onSelected: (_) => setState(() {
                                    kiloControllers[product.id] = TextEditingController(text: '0.0');
                                  }),
                                  selectedColor: AppColor.primary.withOpacity(0.1),
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: isKilo ? AppColor.primary : AppColor.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Quantity control
                  isKilo
                      ? _buildTextField(
                    kiloControllers[product.id]!,
                    "Enter kilo (kg)",
                    LucideIcons.scale,
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minusCircle),
                        iconSize: isSmall ? 20 : 22,
                        color: AppColor.error,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            final currentQty = quantities[product.id] ?? 1;
                            if (currentQty > 1) quantities[product.id] = currentQty - 1;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$quantity',
                          style: TextStyle(fontSize: baseFont(18), fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle),
                        iconSize: isSmall ? 20 : 22,
                        color: AppColor.primary,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            final currentQty = quantities[product.id] ?? 1;
                            if (currentQty < product.totalSacks) quantities[product.id] = currentQty + 1;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// ❌ Remove Icon
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    quantities.remove(product.id);
                    kiloControllers.remove(product.id);
                    context.read<ProductProvider>().removeFromCart(product);
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColor.error,
                  child: Icon(LucideIcons.x, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColor.primary),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColor.primary, width: 1.5),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColor.textSecondary,
            ),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
