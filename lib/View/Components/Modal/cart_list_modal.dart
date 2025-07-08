
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Alert/custom_alert_notification.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import '../../../View_Model/CurrencyProvider.dart';

class CartListModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: _CartListContent(),
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
  final Map<String, int> selectedModes = {}; // 0 = Quantity, 1 = Kilo

  final TextEditingController cashController = TextEditingController();
  final TextEditingController borrowerController = TextEditingController();

  bool isLoan = false;

  late final currencyFormat;

  @override
  void initState() {
    super.initState();
    final cartItems = context.read<ProductProvider>().getCartItems();
    currencyFormat = context.read<CurrencyProvider>().currencyFormat;
    for (var entry in cartItems.entries) {
      final product = entry.key;
      quantities[product.id] = entry.value;
      bool isKiloProduct = product.unit.toLowerCase().contains("kilo") || product.unit.toLowerCase().contains("kg");
      selectedModes[product.id] = isKiloProduct ? 1 : 0;
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

    final removedKeys = kiloControllers.keys.where((key) => !cartItems.keys.any((p) => p.id == key)).toList();
    for (var key in removedKeys) {
      kiloControllers.remove(key)?.dispose();
      quantities.remove(key);
      selectedModes.remove(key);
    }

    double finalTotalPrice = 0;
    double costTotal = 0;
    List<Map<String, dynamic>> checkoutItems = [];

    for (var product in cartItems.keys) {
      bool isKiloProduct = product.unit.toLowerCase().contains("kilo") || product.unit.toLowerCase().contains("kg");
      kiloControllers.putIfAbsent(product.id, () => TextEditingController());

      int selectedMode = selectedModes[product.id] ?? (isKiloProduct ? 1 : 0);

      double qty = selectedMode == 1
          ? double.tryParse(kiloControllers[product.id]?.text ?? '') ?? 0.0
          : (quantities[product.id] ?? 1).toDouble();

      finalTotalPrice += qty * product.retailPrice;
      costTotal += qty * product.costPrice;

      checkoutItems.add({
        'productId': product.id,
        'quantity': qty,
        'isKilo': selectedMode == 1,
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
              _buildDragHandle(),
              _buildPaymentTypeSelector(),
              const SizedBox(height: 24),
              ...cartItems.keys.map((product) => _buildRefinedProductCard(product, productProvider)),
              const SizedBox(height: 24),
              isLoan ? _buildLoanAutocomplete(loanProvider) : _buildHighlightedTotalPaymentField(cashController, "Enter Cash Payment", LucideIcons.wallet2, isNumber: true),
              if (!isLoan) _buildChangeIndicator(change),
              const SizedBox(height: 24),
              _buildFlatSummaryCard(finalTotalPrice, costTotal, profit),
              const SizedBox(height: 20),
              _buildActionButton(
                label: "Confirm Payment",
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
                    productProvider.clearCart();

                    showCustomAlertBox(
                      context,
                      isLoan
                          ? "Loan recorded successfully!\nProfit: \u20b1${profit.toStringAsFixed(2)}"
                          : "Payment completed!\nChange: \u20b1${change.toStringAsFixed(2)}\nProfit: \u20b1${profit.toStringAsFixed(2)}",
                      AlertType.success,
                    );
                  } else {
                    showCustomAlertBox(
                      context,
                      "Transaction failed. Please try again. Payment requires valid cash amount.",
                      AlertType.error,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: "Cancel & Exit",
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

  Widget _buildRefinedProductCard(Product product, ProductProvider productProvider) {
    int selectedMode = selectedModes[product.id] ?? 0;

    kiloControllers.putIfAbsent(product.id, () => TextEditingController(text: '1'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with price overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl.isNotEmpty
                    ? Image.file(
                  File(product.imageUrl),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                    );
                  },
                )
                    : Container(
                  height: 100,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${currencyFormat.format(product.retailPrice)} / ${product.unit}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name & Delete
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.trash2, color: AppColor.error),
                      onPressed: () {
                        setState(() {
                          productProvider.removeFromCart(product);
                          quantities.remove(product.id);
                          kiloControllers.remove(product.id)?.dispose();
                          selectedModes.remove(product.id);
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Choice Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("Quantity"),
                        selected: selectedMode == 0,
                        onSelected: (val) {
                          if (val) setState(() => selectedModes[product.id] = 0);
                        },
                        selectedColor: AppColor.primary.withOpacity(0.15),
                        backgroundColor: Colors.transparent,
                        labelStyle: TextStyle(
                          color: selectedMode == 0 ? AppColor.primary : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 15),
                      ChoiceChip(
                        label: const Text("Kilo"),
                        selected: selectedMode == 1,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              selectedModes[product.id] = 1;
                              kiloControllers[product.id]?.text = '1';
                            });
                          }
                        },
                        selectedColor: AppColor.primary.withOpacity(0.15),
                        backgroundColor: Colors.transparent,
                        labelStyle: TextStyle(
                          color: selectedMode == 1 ? AppColor.primary : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity or Kilo
                selectedMode == 0
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: AppColor.errorText),
                      onPressed: () {
                        setState(() {
                          final current = quantities[product.id] ?? 1;
                          if (current > 1) quantities[product.id] = current - 1;
                        });
                      },
                      splashRadius: 24,
                    ),
                    Text(
                      '${quantities[product.id] ?? 1}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: AppColor.primary),
                      onPressed: () {
                        setState(() {
                          final current = quantities[product.id] ?? 1;
                          quantities[product.id] = current + 1;
                        });
                      },
                      splashRadius: 24,
                    ),
                  ],
                )
                    : TextField(
                  controller: kiloControllers[product.id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Enter kilo quantity",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColor.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text("Cash Payment"),
              selected: !isLoan,
              onSelected: (_) => setState(() => isLoan = false),
              selectedColor: AppColor.primary.withOpacity(0.15),
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: !isLoan ? AppColor.primary : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            ChoiceChip(
              label: const Text("Loan / Credit"),
              selected: isLoan,
              onSelected: (_) => setState(() => isLoan = true),
              selectedColor: AppColor.secondary.withOpacity(0.15),
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isLoan ? AppColor.secondary : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildChangeIndicator(double change) {
    return Padding(
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
            const Text("Change Due:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(
              currencyFormat.format(change),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: change >= 0 ? AppColor.success : AppColor.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFlatSummaryCard(double total, double cost, double profit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highlighted Total Payment
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColor.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildPriceRow(
              "Total Price",
              total,
              AppColor.accent,
              isBold: true,
            ),
          ),

          const SizedBox(height: 12),

          _buildPriceRow("Total Cost", cost, AppColor.warning),

          const SizedBox(height: 16),

          // Estimated Profit (with profit/loss highlight)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: profit >= 0 ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildPriceRow(
              "Estimated Profit",
              profit,
              profit >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButton({
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

  Widget _buildHighlightedTotalPaymentField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primary.withOpacity(0.12), // Highlighted background
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Stronger text for total payment
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
            prefixIcon: Icon(icon, size: 22, color: AppColor.primary),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
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
            currencyFormat.format(value),
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
            hintText: "Search Borrower's Name",
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


}
