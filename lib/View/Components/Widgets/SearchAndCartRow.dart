import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/View/Components/Widgets/ProductSearchDelegate.dart';
import 'package:provider/provider.dart';

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
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notes_rounded, color: AppColor.primary, size: 30),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final products = context
                      .read<ProductProvider>()
                      .getAllProductsWithVariants();
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(products: products),
                  );
                },
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Search products',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Stock In / Out / Adjustment',
              icon: const Icon(LucideIcons.arrowLeftRight, color: AppColor.primary),
              onPressed: () => context.read<TabProvider>().setTab(2),
            ),
          ],
        ),
      ),
    );
  }
}
