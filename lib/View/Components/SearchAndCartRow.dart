import 'package:flutter/material.dart';
import 'package:pocketpos/Provider/CartListProvider.dart';
import 'package:pocketpos/View/Components/AnimatedScannerIcon.dart';
import 'package:pocketpos/View/Components/BouncingCartIcon.dart';
import 'package:pocketpos/View/Components/ProductSearchDelegate.dart';
import 'package:pocketpos/View/Screen/BarcodeScannerScreen.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';

class SearchAndCartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAndCartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<CartListProvider>(
        builder: (context,cartListProvider,_) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 🔍 Search Trigger as Button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final productProvider = Provider.of<ProductProvider>(context, listen: false);
                      showSearch(
                        context: context,
                        delegate: ProductSearchDelegate(products: productProvider.getAllProductsWithVariants()),
                      );
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: const [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Search...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          
                const SizedBox(width: 16),
                AnimatedScannerButton(),
                // 🛒 Cart Icon
                const BouncingCartIcon(),
              ],
            ),
          );
        }
      ),
    );
  }
}
