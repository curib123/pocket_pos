import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';

class ProductMetricsContainer extends StatelessWidget {
  final String heading;
  final String value;
  final String percentage;

  const ProductMetricsContainer({
    super.key,
    required this.heading,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = percentage.contains('-');
    final Color baseColor = isNegative ? AppColor.error : AppColor.success;
    final IconData directionIcon = isNegative ? Icons.arrow_downward : Icons.arrow_upward;

    // Format value with comma
    final String formattedValue = _formatWithComma(value);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
          child: Container(
            height: 150,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  heading.toUpperCase(),
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    color: AppColor.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 26),
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          directionIcon,
                          size: 12,
                          color: AppColor.surface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        percentage,
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(context, 13),
                          fontWeight: FontWeight.w800,
                          color: baseColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatWithComma(String value) {
    try {
      final number = double.tryParse(value.replaceAll(',', '')) ?? 0;
      return NumberFormat("#,##0.##").format(number);
    } catch (_) {
      return value; // fallback if invalid
    }
  }
}
