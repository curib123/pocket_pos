import 'package:flutter/material.dart';
import 'package:retailpos/Helper/AppColor.dart';
import 'package:retailpos/Model/cart_item_model.dart';
import 'package:retailpos/Provider/CartListProvider.dart';
import 'package:retailpos/Provider/CurrencyProvider.dart';
import 'package:retailpos/Provider/ProductProvider.dart';
import 'package:retailpos/Provider/ProductStockProvider.dart';
import 'package:retailpos/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:retailpos/View/Components/Custom/CustomButton.dart';
import 'package:retailpos/View/Components/Custom/CustomTextField.dart';
import 'package:provider/provider.dart';

void showPaymentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 600;
          final TextEditingController paymentController = TextEditingController();

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
                  double change = 0;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      Future<void> handlePayNow() async {
                        final input = paymentController.text.trim();
                        final sanitizedInput = input.replaceAll(RegExp(r'[^\d.]'), '');
                        final payment = double.tryParse(sanitizedInput);

                        if (cartList.isEmpty || sanitizedInput.isEmpty || payment == null || payment < totalAmount) {
                          return;
                        }

                        for (final item in cartList) {
                          try {
                            final int qty = item.quantity.toInt();
                            final String productId = item.productId;
                            final bool isSoldByPack = item.isSoldPerPack;
                            final bool isSoldByPiece = item.isSoldPerPiece;
                            final sellingType = item.sellingType;

                            print("🛒 Selling → ${item.name} x$qty ($sellingType)");
                            bool success = false;

                            if (!isSoldByPack && isSoldByPiece) {
                              print("🧩 Selling by PIECE only → ${item.name} | Qty: $qty");
                              success = await productStockProvider.sellPack(productId, qty);
                            } else if (isSoldByPack && !isSoldByPiece) {
                              print("📦 Selling by PACK only → ${item.name} | Qty: $qty");
                              success = await productStockProvider.sellPack(productId, qty);
                            } else if (isSoldByPack && isSoldByPiece) {
                              print("⚙️ Selling by BOTH pack & piece → ${item.name} | Using: $sellingType | Qty: $qty");
                              success = sellingType == SellingType.pack
                                  ? await productStockProvider.sellPack(productId, qty)
                                  : await productStockProvider.sellPiece(productId, qty, context);
                            } else {
                              print("❌ Invalid selling config for item: ${item.name}");
                              continue;
                            }


                            if (success) {
                              print("✅ Deducted ${item.name}");
                              // ✅ Show success dialog
                              showDialog(
                                context: context,
                                builder: (_) => CustomNotificationDialog(
                                  title: "Payment Successful!",
                                  content: "The transaction was completed and items were deducted from stock.",
                                  type: "success",
                                  onConfirm: () {
                                    int popCount = 3;
                                    while (popCount-- > 0 && Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                      cartListProvider.clearAll();
                                    }
                                  },
                                ),
                              );
                              productProvider.refreshProducts();
                            } else {
                              print("❗ Deduction failed for ${item.name}");
                            }
                          } catch (e) {
                            print("❌ Error deducting ${item.name}: $e");
                          }
                        }

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
                                          currencyProvider.formatAmount(item.getSubtotal()),
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
                                  currencyProvider.formatAmount(totalAmount),
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
                                final input = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
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
                                  currencyProvider.formatAmount(change),
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
                                  child: CustomButton(
                                    text: 'Pay Now',
                                    onPressed: () {
                                      Future.delayed(Duration.zero, () => handlePayNow());
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
