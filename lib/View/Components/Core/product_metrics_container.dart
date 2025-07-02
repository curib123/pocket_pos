import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:animate_do/animate_do.dart';

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
    final IconData directionIcon = isNegative ? LucideIcons.arrowDown : LucideIcons.arrowUp;

    final String formattedValue = _formatWithComma(value);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    heading.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.bold,
                      color: AppColor.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                FadeIn(
                  duration: const Duration(milliseconds: 700),
                  child: Text(
                    formattedValue,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(context, 26),
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Bounce(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
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
      return value;
    }
  }
}
