import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/Helper/HandleSellingDeduction.dart';
import 'package:mobile_stock_inventory/Provider/CartListProvider.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:provider/provider.dart';

void showPaymentDialog(BuildContext context) {
  final TextEditingController paymentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 600;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(20),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
              child: Consumer4<CartListProvider, ProductStockProvider,ProductProvider,CurrencyProvider>(
                builder: (context, cartListProvider, productStockProvider,productProvider, currencyProvider, _) {
                  final cartList = cartListProvider.cartItems;
                  final totalAmount = cartList.fold(0.0, (sum, item) => sum + item.getSubtotal());

                  double change = 0;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      bool isLoading = false;

                      Future<void> handlePayNow() async {
                        final input = paymentController.text.trim();

                        if (input.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => CustomNotificationDialog(
                              onConfirm: () => Navigator.pop(context),
                              title: 'Missing Payment',
                              content: 'Please enter the amount paid by the customer.',
                              type: 'warning',
                            ),
                          );
                          return;
                        }

                        final payment = double.tryParse(input);
                        if (payment == null || payment < totalAmount) {
                          showDialog(
                            context: context,
                            builder: (_) => CustomNotificationDialog(
                              onConfirm: () => Navigator.pop(context),
                              title: 'Invalid or Insufficient Payment',
                              content: 'Please enter a valid payment amount that covers the total cost.',
                              type: 'warning',
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        for (final item in cartList) {
                          await handleSellingDeduction(
                            context,
                            productStockProvider,
                            productProvider,
                            item.productId,
                            item.isSoldPerPack,
                            item.isSoldPerPiece,
                            item.sellingType,
                            item.quantity.toDouble(),
                          );
                        }

                        cartListProvider.clearCart();
                        setState(() => isLoading = false);
                        Navigator.pop(context); // close payment dialog
                      }

                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Payment Summary', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),

                            // 🛒 Cart Items
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
                                          child: Text(
                                            '${item.name} x${item.quantity}',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${currencyProvider.formatAmount(item.getSubtotal())}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const Divider(height: 24),

                            // 💰 Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${currencyProvider.formatAmount(totalAmount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColor.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 🔢 Payment input
                            CustomTextField(
                              label: 'Payment',
                              hintText: '₱0.00',
                              controller: paymentController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final input = double.tryParse(value) ?? 0;
                                setState(() {
                                  change = input - totalAmount;
                                });
                              },
                              isRequired: true,
                              prefixIcon: const Icon(Icons.monetization_on_outlined),
                            ),
                            const SizedBox(height: 8),

                            // 💸 Change
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Change:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${currencyProvider.formatAmount(change)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: change >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Cancel',
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    isFilled: false,
                                    isSlimmer: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : CustomButton(
                                    text: 'Pay Now',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Future.delayed(Duration.zero,(){
                                        handlePayNow();
                                      });
                                    },
                                    isDisabled: change < 0,
                                    isFilled: true,
                                    isSlimmer: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}
