import 'package:flutter/material.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';

class StatGrid extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? guide;

  const StatGrid({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 300;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: constraints.maxWidth * 0.15, // 🌀 Scaled radius
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: constraints.maxWidth * 0.1),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.black87,
                    highlightColor: Colors.deepPurpleAccent.shade100,
                    period: const Duration(seconds: 3),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rf(isWide ? 14 : 12),
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ),
                  if (guide != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        guide!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.rf(isWide ? 12 : 11),
                          color: AppColor.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.rf(isWide ? 20 : 17),
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
