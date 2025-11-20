import 'package:flutter/material.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:shimmer/shimmer.dart';

class GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool seeMore;
  final VoidCallback? onSeeMore;

  const GroupHeader({
    super.key,
    required this.icon,
    required this.title,
    this.seeMore = false,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                child: Icon(icon, size: context.rf(18), color: AppColor.primary),
              ),
              const SizedBox(width: 10),
              Shimmer.fromColors(
                baseColor: Colors.black87,
                highlightColor: Colors.deepPurpleAccent.shade100,
                period: const Duration(seconds: 3),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: context.rf(16), // Responsive font size
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          /// See More (optional)
          if (seeMore && onSeeMore != null)
            GestureDetector(
              onTap: onSeeMore,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    "See more",
                    style: TextStyle(
                      fontSize: context.rf(13), // Responsive font size
                      fontWeight: FontWeight.w500,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 16, color: AppColor.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
