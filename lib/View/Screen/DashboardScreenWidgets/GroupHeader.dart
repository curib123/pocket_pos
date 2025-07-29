
import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:shimmer/shimmer.dart';

class GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool seeMore;
  final VoidCallback? onSeeMore;

  const GroupHeader({
    required this.icon,
    required this.title,
    this.seeMore = false,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Icon + Gradient Shimmer Title
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(icon, size: 18, color: AppColor.primary),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: Colors.black87,
                highlightColor: Colors.deepPurpleAccent.shade100,
                period: const Duration(seconds: 3),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87, // actual text color overridden by shimmer
                  ),
                ),
              ),
            ],
          ),

          /// See More (if enabled)
          if (seeMore && onSeeMore != null)
            GestureDetector(
              onTap: onSeeMore,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: const [
                  Text(
                    "See more",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16, color: AppColor.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

