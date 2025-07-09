import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View/Components/Alert/custom_alert_notification.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import '../../../View_Model/CurrencyProvider.dart';

class CartPaymentModal {
  static void show(BuildContext context, {
    required Map<String, int> quantities,
    required Map<String, String> kiloQuantities,
    required Map<String, int> selectedModes,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _CartPaymentContent(
          quantities: quantities,
          kiloQuantities: kiloQuantities,
          selectedModes: selectedModes,
        ),
      ),
    );
  }
}

class _CartPaymentContent extends StatefulWidget {
  final Map<String, int> quantities;
  final Map<String, String> kiloQuantities;
  final Map<String, int> selectedModes;

  const _CartPaymentContent({
    super.key,
    required this.quantities,
    required this.kiloQuantities,
    required this.selectedModes,
  });

  @override
  State<_CartPaymentContent> createState() => _CartPaymentContentState();
}

class _CartPaymentContentState extends State<_CartPaymentContent> {
  final TextEditingController cashController = TextEditingController();
  final TextEditingController borrowerController = TextEditingController();
  bool isLoan = false;
  late final currencyFormat;

  @override
  void initState() {
    super.initState();
    currencyFormat = context.read<CurrencyProvider>().currencyFormat;
  }

  @override
  void dispose() {
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

    double total = 0;
    double costTotal = 0;
    List<Map<String, dynamic>> checkoutItems = [];

    for (var product in cartItems.keys) {
      int selectedMode = widget.selectedModes[product.id] ?? 0;
      double quantity = selectedMode == 1
          ? double.tryParse(widget.kiloQuantities[product.id] ?? '0') ?? 0
          : (widget.quantities[product.id] ?? 1).toDouble();

      total += quantity * product.retailPrice;
      costTotal += quantity * product.costPrice;

      checkoutItems.add({
        'productId': product.id,
        'quantity': quantity,
        'isKilo': selectedMode == 1,
      });
    }

    final profit = total - costTotal;
    final change = buyerCash - total;

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
              isLoan
                  ? _buildLoanAutocomplete(loanProvider)
                  : _buildCashInput(),
              if (!isLoan) _buildChangeDisplay(change),
              const SizedBox(height: 24),
              _buildSummaryCard(total, costTotal, profit),
              const SizedBox(height: 20),
              CustomButton(
                label: "Confirm Payment",
                icon: LucideIcons.checkCircle2,
                color: AppColor.textPrimary,
                onPressed: () async {
                  final result = await productProvider.checkoutCart(
                    cartItems: checkoutItems,
                    isLoan: isLoan,
                    buyerCash: buyerCash,
                    borrowerName: borrowerController.text.trim(),
                    loanProvider: isLoan ? loanProvider : null,
                  );

                  if (result != null) {
                    productProvider.clearCart();
                    showCustomAlertBox(
                      context,
                      isLoan
                          ? "Loan recorded successfully!\nProfit: \u20b1${(result['profit'] ?? 0.0).toStringAsFixed(2)}"
                          : "Payment completed!\nChange: \u20b1${(result['change'] ?? 0.0).toStringAsFixed(2)}\nProfit: \u20b1${(result['profit'] ?? 0.0).toStringAsFixed(2)}",
                      AlertType.success,
                    );


                  }
                  else {
                    showCustomAlertBox(
                      context,
                      "Transaction failed. Please try again.",
                      AlertType.error,
                    );
                  }
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: AppColor.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  Widget _buildPaymentTypeSelector() {
    return Center(
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("Cash Payment"),
            selected: !isLoan,
            onSelected: (_) => setState(() => isLoan = false),
            selectedColor: AppColor.primary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: !isLoan ? AppColor.primary : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          ChoiceChip(
            label: const Text("Loan / Credit"),
            selected: isLoan,
            onSelected: (_) => setState(() => isLoan = true),
            selectedColor: AppColor.secondary.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isLoan ? AppColor.secondary : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInput() {
    return TextField(
      controller: cashController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: "Enter Cash Payment",
        prefixIcon: Icon(LucideIcons.wallet2, color: AppColor.primary),
        filled: true,
        fillColor: AppColor.primary.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (_) => setState(() {}),
    );
  }


  Widget _buildChangeDisplay(double change) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: change >= 0 ? AppColor.success.withOpacity(0.1) : AppColor.error.withOpacity(0.1),
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
    );
  }

  Widget _buildSummaryCard(double total, double cost, double profit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColor.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildSummaryRow("Total Price", total, AppColor.accent, isBold: true, big: true),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow("Total Cost", cost, AppColor.warning),
          const SizedBox(height: 16),
          _buildSummaryRow(
            "Estimated Profit",
            profit,
            profit >= 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isBold = false, bool big = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: big ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontSize: big ? 17 : 15,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }



  Widget _buildLoanAutocomplete(LoanProvider loanProvider) {
    return Autocomplete<LoanPerson>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<LoanPerson>.empty();
        return loanProvider.loans.where((option) =>
            option.name.toLowerCase().contains(textEditingValue.text.toLowerCase())).take(5);
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        controller.text = borrowerController.text;
        controller.addListener(() => borrowerController.text = controller.text);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "Search Borrower's Name",
            prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade600),
            filled: true,
            fillColor: AppColor.success.withOpacity(0.10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        );
      },
      onSelected: (selected) {
        borrowerController.text = selected.name;
      },
    );
  }
}
