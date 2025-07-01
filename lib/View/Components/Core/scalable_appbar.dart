import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Custom/custom_search_delegate.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';

class ScalableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final double height;
  final bool showSearchBar;
  final bool isTitle; // NEW

  const ScalableAppBar({
    super.key,
    required this.title,
    this.actions,
    this.height = kToolbarHeight,
    this.showSearchBar = true,
    this.isTitle = true, // NEW
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Title
              if (isTitle)
                Flexible(
                  flex: showSearchBar ? 2 : 1,
                  fit: FlexFit.tight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ),
                ),

              // Search Bar or Empty Widget
              if (showSearchBar && isTitle) const SizedBox(width: 16),

              if (showSearchBar)
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: CustomSearchDelegate(),
                      );
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Flexible(
                            child: Text(
                              "Search Items...",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColor.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.search,
                              color: AppColor.textSecondary, size: 25),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      actions: actions,
    );
  }
}
