import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/View/Components/Widgets/AnimatedScannerIcon.dart';
import 'package:nextpos/View/Components/Widgets/BouncingCartIcon.dart';
import 'package:nextpos/View/Components/Widgets/ProductSearchDelegate.dart';
import 'package:provider/provider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';

class SearchAndCartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAndCartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            IconButton(
              icon:  Icon(Icons.notes_rounded, color: AppColor.primary,size: 30,),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final productProvider = Provider.of<ProductProvider>(context, listen: false);
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(
                      products: productProvider.getAllProductsWithVariants(),
                    ),
                  );
                },
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Row(
                    children: [
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
            const AnimatedScannerButton(),
            const SizedBox(width: 8),
            const BouncingCartIcon(),
          ],
        ),
      ),
    );
  }
}
