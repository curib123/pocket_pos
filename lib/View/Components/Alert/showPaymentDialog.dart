import 'package:flutter/material.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Provider/LoanProvider.dart';
import 'package:provider/provider.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Model/cart_item_model.dart';
import 'package:nextpos/Provider/CartListProvider.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:nextpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:nextpos/View/Components/Custom/CustomSwitchPill.dart';
import 'package:nextpos/View/Components/Custom/CustomTextField.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController paymentController = TextEditingController();
  final TextEditingController loanerNameController = TextEditingController();
  String selectedPaymentType = 'Cash';
  double change = 0;

  @override
  void dispose() {
    paymentController.dispose();
    loanerNameController.dispose();
    super.dispose();
  }

  Future<void> handlePayment({
    required List<CartItem> cartList,
    required double totalAmount,
    required CartListProvider cartListProvider,
    required ProductStockProvider productStockProvider,
    required ProductProvider productProvider,
  }) async {
    final paymentInput = paymentController.text.trim();
    final sanitizedInput = paymentInput.replaceAll(RegExp(r'[^\d.]'), '');
    final payment = double.tryParse(sanitizedInput);
    final loanerName = loanerNameController.text.trim();
    final isLoan = selectedPaymentType == 'Loan';

    if (cartList.isEmpty) return;

    if (isLoan && loanerName.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => CustomNotificationDialog(
          title: "Missing Name",
          content: "Please enter the loaner's name before confirming the loan.",
          type: "error",
          onConfirm: () => Navigator.pop(context),
        ),
      );
      return;
    }

    if (!isLoan && (sanitizedInput.isEmpty || payment == null || payment < totalAmount)) {
      return;
    }

    for (final item in cartList) {
      try {
        final qty = item.quantity.toInt();
        final productId = item.productId;
        final sellingType = item.sellingType;

        bool success = false;
        if (item.isSoldPerPiece && !item.isSoldPerPack) {
          success = await productStockProvider.sellPack(productId, qty, StockLogReason.sold,true,
              isLoan: isLoan, borrowName: loanerName);
        } else if (item.isSoldPerPack && !item.isSoldPerPiece) {
          success = await productStockProvider.sellPack(productId, qty, StockLogReason.sold,false,
              isLoan: isLoan, borrowName: loanerName);
        } else {
          success = sellingType == SellingType.pack
              ? await productStockProvider.sellPack(productId, qty, StockLogReason.sold,false,
              isLoan: isLoan, borrowName: loanerName)
              : await productStockProvider.sellItemsPerPack(productId, qty, StockLogReason.sold, context,
              isLoan: isLoan, borrowName: loanerName);
        }

        if (!success) {
          print("❗ Deduction failed for ${item.name}");
        }
      } catch (e) {
        print("❌ Error processing ${item.name}: $e");
      }
    }

    await showDialog(
      context: context,
      builder: (_) => CustomNotificationDialog(
        title: isLoan ? "Loan Recorded Successfully!" : "Payment Successful!",
        content: isLoan
            ? "This transaction was marked as a loan. Items have been deducted from stock and logged under the borrower’s name."
            : "Transaction complete. Items have been deducted from stock.",
        type: "success",
        onConfirm: () {
          int popCount = 3;
          while (popCount-- > 0 && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          cartListProvider.clearAll();
        },
      ),
    );

  }
  double roundTo2Decimals(double value) => double.parse(value.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(20),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
        child: Consumer4<CartListProvider, ProductStockProvider, ProductProvider, CurrencyProvider>(
          builder: (context, cartListProvider, productStockProvider, productProvider, currencyProvider, _) {
            final cartList = cartListProvider.cartItems;
            final totalAmount = cartList.fold(0.0, (sum, item) => sum + item.getSubtotal());

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CustomSwitchPill(
                      options: ['Cash', 'Loan'],
                      selected: selectedPaymentType,
                      onSelected: (value) {
                        setState(() {
                          selectedPaymentType = value;
                          change = 0;
                          paymentController.clear();
                          loanerNameController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Payment Summary', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      itemCount: cartList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final item = cartList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${item.name} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                              ),
                              Text(currencyProvider.formatAmount(item.getSubtotal()), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        currencyProvider.formatAmount(totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColor.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Consumer<LoanProvider>(
                    builder: (context, loanProvider, child) {
                      final loanerNames = loanProvider.getAllLoanerNames();

                      return selectedPaymentType == 'Cash'
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            key: ValueKey(selectedPaymentType),
                            label: 'Payment',
                            hintText: '₱0.00',
                            controller: paymentController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final sanitized = value.replaceAll(RegExp(r'[^\d.]'), '');
                              final input = double.tryParse(sanitized) ?? 0;
                              setState(() {
                                change = roundTo2Decimals(input - totalAmount);
                              });

                            },
                            isRequired: true,
                            prefixIcon: const Icon(Icons.monetization_on_outlined),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              change < 0
                                  ? 'Insufficient by ${currencyProvider.formatAmount(change.abs())}'
                                  : 'Change: ${currencyProvider.formatAmount(change)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: change < 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      )
                          : Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return loanerNames.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          loanerNameController.text = selection;
                        },
                        fieldViewBuilder: (
                            BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted,
                            ) {
                          fieldTextEditingController.text = loanerNameController.text;
                          fieldTextEditingController.selection = loanerNameController.selection;

                          return CustomTextField(
                            key: ValueKey(selectedPaymentType),
                            label: 'Loaner Name',
                            hintText: 'Enter borrower’s name',
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            keyboardType: TextInputType.text,
                            onChanged: (val) {
                              loanerNameController.text = val;
                              loanerNameController.selection = fieldTextEditingController.selection;
                            },
                            isRequired: true,
                            prefixIcon: const Icon(Icons.person_outline),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                          isFilled: false,
                          isSlimmer: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: selectedPaymentType == 'Loan' ? 'Confirm Loan' : 'Pay Now',
                          onPressed: () {
                            Future.delayed(Duration.zero, () => handlePayment(
                              cartList: cartList,
                              totalAmount: totalAmount,
                              cartListProvider: cartListProvider,
                              productStockProvider: productStockProvider,
                              productProvider: productProvider,
                            ));
                          },
                          isDisabled: false,
                          isFilled: true,
                          isSlimmer: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
