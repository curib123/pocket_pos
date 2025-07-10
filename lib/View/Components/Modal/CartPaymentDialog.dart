import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:provider/provider.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/View/Components/Alert/custom_alert_notification.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import '../../../View_Model/CurrencyProvider.dart';

class CartPaymentDialog {
  static void show(BuildContext context, {
    required Map<String, int> quantities,
    required Map<String, String> kiloQuantities,
    required Map<String, int> selectedModes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final isLargeScreen = size.width >= 600; // ✅ Adjust threshold as needed

        return Dialog(
          backgroundColor: AppColor.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? size.width * 0.5 : size.width * 1, // ✅ Half for large screens
              maxHeight: size.height * 1, // Optional: control height too
            ),
            child: _CartPaymentContent(
              quantities: quantities,
              kiloQuantities: kiloQuantities,
              selectedModes: selectedModes,
            ),
          ),
        );
      },
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
  FocusNode _cashFocusNode = FocusNode();



  @override
  void initState() {
    super.initState();
    currencyFormat = context.read<CurrencyProvider>().currencyFormat;
  }

  @override
  void dispose() {
    cashController.dispose();
    _cashFocusNode.dispose();
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPaymentTypeSelector(),
            const SizedBox(height: 10),
            _buildSummaryCard(total, costTotal, profit),
            const SizedBox(height: 10),
            isLoan
                ? _buildLoanAutocomplete(loanProvider)
                : _buildCashInput(),
            if (!isLoan) _buildChangeDisplay(change),
            const SizedBox(height: 24),
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
                  Navigator.of(context).pop();  // Close Dialog
                  showCustomAlertBox(
                    context,
                    isLoan
                        ? "Loan recorded successfully!\nProfit: \u20b1${(result['profit'] ?? 0.0).toStringAsFixed(2)}"
                        : "Payment completed!\nChange: \u20b1${(result['change'] ?? 0.0).toStringAsFixed(2)}\nProfit: \u20b1${(result['profit'] ?? 0.0).toStringAsFixed(2)}",
                    AlertType.success,
                  );
                } else {
                  showCustomAlertBox(
                    context,
                    "Transaction failed. Please try again.",
                    AlertType.error,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("Cash"),
            selected: !isLoan,
            onSelected: (_) => setState(() => isLoan = false),
            selectedColor: AppColor.primary,
            labelStyle: TextStyle(
              color: !isLoan ? Colors.white : Colors.grey.shade700, // ✅ White text when selected
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            showCheckmark: true,                     // ✅ Show checkmark
            checkmarkColor: Colors.white,            // ✅ White checkmark
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          ChoiceChip(
            label: const Text("Loan"),
            selected: isLoan,
            onSelected: (_) => setState(() => isLoan = true),
            selectedColor: AppColor.secondary,
            labelStyle: TextStyle(
              color: isLoan ? Colors.white : Colors.grey.shade700, // ✅ White text when selected
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            showCheckmark: true,                     // ✅ Show checkmark
            checkmarkColor: Colors.white,            // ✅ White checkmark
            backgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ],
      ),
    );
  }



  Widget _buildCashInput() {
    final List<String> cashOptions =
    List.generate(20000, (index) => ((index + 1) * 5).toString()); // ₱5 to ₱10,000

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RawAutocomplete<String>(
        textEditingController: cashController,
        focusNode: _cashFocusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();

          return cashOptions
              .where((option) => option.startsWith(textEditingValue.text))
              .take(3); // limit to 3 results
        },
        displayStringForOption: (option) => option,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: "Enter Cash Payment",
              prefixIcon: Icon(LucideIcons.wallet2, color: AppColor.primary),
              filled: true,
              fillColor: AppColor.primary.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (_) {
              if (mounted) setState(() {});
            },
            onSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text("₱$option"),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          );
        },
        onSelected: (String value) {
          if (mounted) setState(() {});
        },
      ),
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
