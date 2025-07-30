
import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:shimmer/shimmer.dart';

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? guide;

  const StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.guide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: context.rf(20),
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: context.rf(18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.black87,
                  highlightColor: Colors.deepPurpleAccent.shade100,
                  period: const Duration(seconds: 3),
                  child: Text(
                    label,
                    style:  TextStyle(
                      fontSize: context.rf(14),
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),

                if (guide != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      guide!,
                      style:  TextStyle(
                        fontSize:  context.rf(12),
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: context.rf(18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
