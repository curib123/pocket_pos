import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Provider/CartListProvider.dart';
import 'package:pocketpos/View/Components/Modal/CartListModal.dart';
import 'package:provider/provider.dart';

class BouncingCartIcon extends StatelessWidget {
  final Color? iconColor;
  const BouncingCartIcon({
    super.key,  this.iconColor = AppColor.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartListProvider>(
      builder: (context,cartProvider,_) {
        return Bounce(
          infinite: cartProvider.cartItems.length != 0 ? true : false,
          from: 10, // subtle bounce
          duration: const Duration(seconds: 1),
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: (){
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => FractionallySizedBox(
                      heightFactor: 0.90,
                      child: CartListModal(),
                    ),
                  );

                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.shopping_cart_outlined, size: 40,color: iconColor,),
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
