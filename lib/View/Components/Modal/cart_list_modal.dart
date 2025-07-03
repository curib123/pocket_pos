import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/View/Components/Alert/custom_alert_notification.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
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
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
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
  void initState() {
    super.initState();
    final cartItems = context.read<ProductProvider>().getCartItems();
    for (var entry in cartItems.entries) {
      quantities[entry.key.id] = entry.value;
    }
  }

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
    final productProvider = context.watch<ProductProvider>();
    final loanProvider = context.read<LoanProvider>();
    final cartItems = productProvider.getCartItems();

    // Clean up controllers and quantities for removed products
    final removedKeys = kiloControllers.keys.where((key) => !cartItems.keys.any((p) => p.id == key)).toList();
    for (var key in removedKeys) {
      kiloControllers.remove(key)?.dispose();
      quantities.remove(key);
    }

    double finalTotalPrice = 0;
    double costTotal = 0;

    List<Map<String, dynamic>> checkoutItems = [];

    for (var product in cartItems.keys) {
      final isKiloProduct = product.unit.toLowerCase().contains('kilo') || product.unit.toLowerCase().contains('kg');

      // Ensure controller exists for kilo products
      if (isKiloProduct) {
        kiloControllers.putIfAbsent(product.id, () => TextEditingController());
      }

      double qty = 1.0;
      if (isKiloProduct) {
        qty = double.tryParse(kiloControllers[product.id]?.text ?? '') ?? 0.0;
      } else {
        qty = (quantities[product.id] ?? 1).toDouble();
      }

      final productTotalPrice = qty * product.retailPrice;
      final productCost = qty * product.costPrice;

      finalTotalPrice += productTotalPrice;
      costTotal += productCost;

      checkoutItems.add({
        'productId': product.id,
        'quantity': qty,
        'isKilo': isKiloProduct,
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
              ...cartItems.keys.map((product) => _buildProductCard(product, productProvider)).toList(),
              const SizedBox(height: 24),
              if (!isLoan)
                _buildTextField(cashController, "Enter Cash Payment", Icons.payments, isNumber: true)
              else
                _buildLoanAutocomplete(loanProvider),
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
                        const Text("Your Change:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          "₱${change.toStringAsFixed(2)}",
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
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColor.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _buildPriceRow("Total Amount to Pay", finalTotalPrice, AppColor.secondary),
                      const SizedBox(height: 8),
                      _buildPriceRow("Total Cost", costTotal, AppColor.warning),
                      const Divider(height: 24),
                      _buildPriceRow("Estimated Profit", profit, profit >= 0 ? AppColor.accent : AppColor.error, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildGlowingButton(
                label: "Pay Now",
                icon: LucideIcons.checkCircle2,
                backgroundColor: AppColor.primary,
                shadowColor: AppColor.primary,
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

                    // Show success alert first
                    showCustomAlertBox(
                      context,
                      isLoan
                          ? "Loan recorded successfully!\nProfit: ₱${profit.toStringAsFixed(2)}"
                          : "Payment successful!\nChange: ₱${change.toStringAsFixed(2)}\nProfit: ₱${profit.toStringAsFixed(2)}",
                      AlertType.success,
                    );


                  } else {
                    // Show error alert
                    showCustomAlertBox(
                      context,
                      "Something went wrong. Please try again.Pay Now !! Need Cash",
                      AlertType.error,
                    );
                  }

                },
              ),
              const SizedBox(height: 12),
              _buildGlowingButton(
                label: "Exit Without Saving",
                icon: LucideIcons.logOut,
                backgroundColor: AppColor.error,
                shadowColor: AppColor.error,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanAutocomplete(LoanProvider loanProvider) {
    return Autocomplete<LoanPerson>(
      displayStringForOption: (LoanPerson p) => p.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<LoanPerson>.empty();
        return loanProvider.loans.where((LoanPerson option) {
          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
        }).take(5);
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        controller.text = borrowerController.text;
        controller.addListener(() => borrowerController.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText: "Enter Borrower's Name",
            prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade600),
            filled: true,
            fillColor: AppColor.success.withOpacity(0.10),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      onSelected: (LoanPerson selected) {
        setState(() {
          borrowerController.text = selected.name;
        });
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
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
            style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 15, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color shadowColor,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider productProvider) {
    final isKiloProduct = product.unit.toLowerCase().contains("kilo") || product.unit.toLowerCase().contains("kg");
    kiloControllers.putIfAbsent(product.id, () => TextEditingController());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      color: AppColor.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                GestureDetector(
                  child: Icon(LucideIcons.xCircle, color: AppColor.error),
                  onTap: () {
                    setState(() {
                      productProvider.removeFromCart(product);
                      quantities.remove(product.id);
                      kiloControllers.remove(product.id)?.dispose();
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("₱${product.retailPrice.toStringAsFixed(2)} / ${product.unit}", style: const TextStyle(fontSize: 14)),
                if (!isKiloProduct)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: AppColor.errorText),
                        onPressed: () {
                          setState(() {
                            final current = quantities[product.id] ?? 1;
                            if (current > 1) quantities[product.id] = current - 1;
                          });
                        },
                      ),
                      Text('${quantities[product.id] ?? 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: AppColor.primary),
                        onPressed: () {
                          setState(() {
                            final current = quantities[product.id] ?? 1;
                            quantities[product.id] = current + 1;
                          });
                        },
                      ),
                    ],
                  ),
                if (isKiloProduct)
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: kiloControllers[product.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Enter kilo",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColor.primary),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
