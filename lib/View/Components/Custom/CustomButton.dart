import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/View/Components/ResponsiveText.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
  final bool isDisabled;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double iconSize;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
    this.isDisabled = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize = 20, // Bigger icon
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color fallbackBorderColor = borderColor ?? AppColor.primary;

    final Color effectiveBackground = isDisabled
        ? fallbackBorderColor.withOpacity(0.4)
        : backgroundColor ?? (isFilled ? AppColor.primary : Colors.transparent);

    final Color effectiveText = isDisabled
        ? AppColor.textSecondary.withOpacity(0.5)
        : textColor ?? (isFilled ? AppColor.surface : fallbackBorderColor);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveText,
      elevation: isFilled && !isDisabled ? 1.5 : 0,
      shadowColor: isFilled && !isDisabled ? Colors.black12 : Colors.transparent,
      side: isFilled || isDisabled
          ? null
          : BorderSide(color: effectiveText.withOpacity(0.7), width: 1.2),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 40, // Bigger height
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: buttonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: iconSize, color: effectiveText),
            if (icon != null) const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: context.rf(12), // Bigger font
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: effectiveText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
