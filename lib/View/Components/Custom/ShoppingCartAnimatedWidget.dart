import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/Modal/CartSelectionModal.dart';
import 'package:paninda/View/Components/Modal/cart_list_modal.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

/// ✅ Animated Running Cart Icon Widget with Provider Inside
class ShoppingCartAnimatedwidget extends StatelessWidget {
  final Color iconColor;

  const ShoppingCartAnimatedwidget({
    super.key,
    this.iconColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final count = provider.getCartItems().length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () {
              CartSelectionModal.show(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Bounce(
                        infinite: count > 0,
                        from: 15,
                        duration: const Duration(milliseconds: 700),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          size: 35,
                          color: iconColor,
                        ),
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Bounce(
                          infinite: true,
                          from: 15,
                          duration: const Duration(milliseconds: 700),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
