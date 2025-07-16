import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mobile_stock_inventory/Provider/CartProvider.dart';
import 'package:provider/provider.dart';

class BouncingCartIcon extends StatelessWidget {


  const BouncingCartIcon({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context,cartProvider,_) {
        return Bounce(
          infinite: true,
          from: 10, // subtle bounce
          duration: const Duration(seconds: 1),
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: (){

                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.shopping_cart_outlined, size: 40),
                ),
              ),
              if (cartProvider.cartItems.length > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 10),
                    child: Center(
                      child: Text(
                        '${cartProvider.cartItems.length.toString()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}
