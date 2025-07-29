import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:shimmer/shimmer.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
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
                    fontSize: isWide ? 15 : 13,
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
                      fontSize: isWide ? 13 : 11.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isWide ? 20 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
