import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Custom/ShoppingCartAnimatedWidget.dart';
import 'package:paninda/View/Components/Custom/custom_search_delegate.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

class ScalableAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScalableAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Flexible(
                      child: Text(
                        "Search Product...",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
           ShoppingCartAnimatedwidget(iconColor: AppColor.primary.withOpacity(0.7),),
        ],
      ),
    );
  }
}
