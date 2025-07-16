import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/View/Components/BouncingCartIcon.dart';

class SearchAndCartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAndCartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 🔍 Search Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          debugPrint("Searching for: $value");
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 🛒 Reusable Bouncing Cart Icon
            BouncingCartIcon(),
          ],
        ),
      ),
    );
  }
}
