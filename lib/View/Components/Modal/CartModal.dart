import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';
import 'package:mobile_pos_inventory/Provider/CartProvider.dart';
import 'package:mobile_pos_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomSwitchPill.dart';
import 'package:mobile_pos_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_pos_inventory/View/Components/Alert/CustomNotificationDialog.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<String, bool> useTextField = {};
  final Map<String, TextEditingController> controllers = {};
  final Map<String, double> quantities = {};

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: AppBar(
        title:  Text("Cart List",style: TextStyle(color: AppColor.textPrimary,fontSize: 25,fontWeight: FontWeight.bold),),
        centerTitle: true,
        leading: GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new,color: AppColor.textPrimary,),
        ),
      ),
      body: Consumer3<CartProvider, CurrencyProvider,ProductProvider>(
        builder: (context, cartProvider, currencyProvider,productProvider, _) {
          final cart = cartProvider.cartItems;

          if (cart.isEmpty) {
            return const Center(
              child: Text(
                "Your cart is empty.",
                style: TextStyle(fontSize: 16, color: AppColor.textSecondary),
              ),
            );
          }

          final totalAmount = cart.fold<double>(0, (sum, product) {
            final qty = quantities[product.name] ?? product.totalQuantity;
            return sum + (qty * product.retailPrice);
          });

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = cart[index];
                      final key = product.name;

                      useTextField.putIfAbsent(key, () => false);
                      controllers.putIfAbsent(key, () => TextEditingController());
                      quantities.putIfAbsent(key, () => product.totalQuantity);

                      final isInput = useTextField[key]!;
                      final inputCtrl = controllers[key]!;
                      final quantity = quantities[key]!;
                      final price = product.retailPrice;
                      final subtotal = quantity * price;
                      final maxQuantity = productProvider.getProductByName(product.name)?.totalQuantity;

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColor.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: product.imageUrl.isNotEmpty &&
                                      File(product.imageUrl).existsSync()
                                      ? Image.file(
                                    File(product.imageUrl),
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    width: 36,
                                    height: 36,
                                    color: AppColor.border,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 16,
                                      color: AppColor.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${currencyProvider.currencyFormat.currencySymbol}${price.toStringAsFixed(2)} / ${product.unit}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    LucideIcons.trash,
                                    size: 18,
                                    color: AppColor.error,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => CustomConfirmDialog(
                                        title: 'Remove Item?',
                                        content: 'Are you sure you want to remove "${product.name}" from your cart?',
                                        onConfirm: () {
                                          cartProvider.removeFromCart(product.name);
                                          setState(() {
                                            useTextField.remove(key);
                                            controllers[key]?.dispose();
                                            controllers.remove(key);
                                            quantities.remove(key);
                                          });

                                          cartProvider.cartItems.isEmpty ? Navigator.pop(context) : null;
                                        },
                                      ),
                                    );
                                  },
                                ),

                              ],
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: CustomSwitchPill(
                                options: ['Stepper', 'Input'],
                                selected: isInput ? 'Input' : 'Stepper',
                                onSelected: (label) {
                                  setState(() {
                                    useTextField[key] = label == 'Input';
                                    quantities[key] = product.totalQuantity;
                                    inputCtrl.text = product.totalQuantity.toString();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            isInput
                                ? CustomTextField(
                              label: '',
                              controller: inputCtrl,
                              keyboardType: TextInputType.number,
                              hintText: 'Qty',
                              onChanged: (value) {
                                final parsed = double.tryParse(value) ?? 0;
                                final clamped = parsed.clamp(0.0, maxQuantity!);
                                setState(() {
                                  quantities[key] = clamped;
                                  if (parsed != clamped) {
                                    inputCtrl.text = clamped.toString();
                                    inputCtrl.selection = TextSelection.fromPosition(
                                      TextPosition(offset: inputCtrl.text.length),
                                    );
                                  }
                                });
                              },

                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 25, color: AppColor.primary),
                                  onPressed: () {
                                    if (quantity > 0) {
                                      setState(() {
                                        quantities[key] = quantity - 1;
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 25, color: AppColor.primary),
                                  onPressed: () {
                                    if (quantity < maxQuantity!) {
                                      setState(() {
                                        quantities[key] = quantity + 1;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Subtotal:",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                                Text(
                                  "${currencyProvider.currencyFormat.currencySymbol}${subtotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.primary,
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

                // Total Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text("₱${totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary)),
                    ],
                  ),
                ),

                // Proceed Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: CustomButton(
                    text: 'Proceed Payment',
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      final selectedQuantities = quantities.entries
                          .where((e) => e.value > 0)
                          .toList();

                      if (selectedQuantities.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (_) => CustomNotificationDialog(
                            onConfirm: () => Navigator.pop(context),
                            type: "warning",
                            title: 'Invalid Quantity',
                            content:
                            'Please enter valid quantities for at least one product.',
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Order Placed"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...selectedQuantities.map((e) {
                                final product = cartProvider.cartItems
                                    .firstWhere((p) => p.name == e.key);
                                final subtotal = product.retailPrice * e.value;
                                return Text(
                                    "${e.key} - ${e.value} × ₱${product.retailPrice} = ₱${subtotal.toStringAsFixed(2)}");
                              }),
                              const SizedBox(height: 10),
                              Text("Total: ₱${totalAmount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                cartProvider.clearCart();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
