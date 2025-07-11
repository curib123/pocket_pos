import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class BouncingCartIcon extends StatelessWidget {
  final int cartCount;
  final VoidCallback onTap;

  const BouncingCartIcon({
    super.key,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Bounce(
      infinite: true,
      from: 10, // subtle bounce
      duration: const Duration(seconds: 1),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.shopping_cart_outlined, size: 40),
            ),
          ),
          if (cartCount > 0)
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
                    '$cartCount',
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
}
