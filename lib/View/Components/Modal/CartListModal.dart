import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:nextpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Provider/CartListProvider.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/View/Components/Alert/showPaymentDialog.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:nextpos/View/Components/Custom/CustomStepper.dart';
import 'package:nextpos/View/Components/Custom/CustomSwitchPill.dart';

class CartListModal extends StatelessWidget {
  const CartListModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Consumer2<CartListProvider, ProductStockProvider>(
            builder: (context, cartProvider, productStockProvider, _) {
              final cartItems = cartProvider.cartItems;
              final currency = context.read<CurrencyProvider>();
              final double total = cartProvider.totalPrice;

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new),
                        ),
                        const SizedBox(width: 30),
                        const Text(
                          "Your Cart",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cart Items
                  Expanded(
                    child: cartItems.isEmpty
                        ? const _EmptyCartState()
                        : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CartItemTile(
                        name: cartItems[index].name,
                      ),
                    ),
                  ),

                  // Bottom Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              currency.formatAmount(total),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Cancel',
                                icon: Icons.cancel_rounded,
                                borderColor: AppColor.errorText,
                                isFilled: false,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                backgroundColor: AppColor.primary,
                                text: 'Proceed Payment',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const PaymentDialog(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}


class _CartItemTile extends StatefulWidget {
  final String name; // ✅ Now using name
  const _CartItemTile({required this.name});

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  String mode = 'Stepper';

  @override
  Widget build(BuildContext context) {
    final currency = context.read<CurrencyProvider>();

    return Consumer<CartListProvider>(
      builder: (context, cartProvider, _) {
        final item = cartProvider.getCartItem(widget.name); // ✅ by name
        if (item == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 6),
              CustomSwitchPill(
                options: const ['Stepper', 'Input'],
                selected: mode,
                onSelected: (val) => setState(() => mode = val),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImage(imagePath: item.imagePath),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 25,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => CustomConfirmDialog(
                                    title: "Remove Item?",
                                    content: "Are you sure you want to remove \"${item.name}\" from your cart?",
                                    onConfirm: () {
                                      cartProvider.removeFromCart(item.name);
                                    },
                                  ),
                                );
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              currency.formatAmount(item.price),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColor.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "× ${item.maxQuantity - item.quantity}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CustomStepperField(
                value: item.quantity,
                min: 1,
                max: item.maxQuantity,
                useTextInput: mode == 'Input',
                themeColor: AppColor.primary,
                onChanged: (newQty) {
                  cartProvider.updateQuantity(item.name, newQty); // ✅ update by name
                  debugPrint("🔢 Updated quantity for ${item.name} to $newQty");
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    currency.formatAmount(item.getSubtotal()),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imagePath;
  const _ProductImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        image: imagePath != null
            ? DecorationImage(
          image: FileImage(File(imagePath!)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: imagePath == null
          ? const Icon(Icons.image_not_supported, size: 20, color: Colors.grey)
          : null,
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.shoppingCart, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Your cart’s chillin’... 💤",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add something, let’s get this stock party started!",
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
