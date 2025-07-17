import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/View/Components/ResponsiveText.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
  final bool isDisabled; // 🚨 New
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double iconSize;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFilled = true,
    this.isDisabled = false, // ✅ Default to false
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackground = isDisabled
        ? AppColor.border.withOpacity(0.5)
        : backgroundColor ?? (isFilled ? AppColor.primary : Colors.transparent);

    final Color effectiveText = isDisabled
        ? AppColor.textSecondary.withOpacity(0.5)
        : textColor ?? (isFilled ? AppColor.surface : AppColor.primary);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveText,
      elevation: isFilled && !isDisabled ? 2 : 0,
      shadowColor: isFilled && !isDisabled ? Colors.black26 : Colors.transparent,
      side: isFilled || isDisabled
          ? null
          : BorderSide(color: effectiveText.withOpacity(0.7), width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: buttonStyle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(icon, size: iconSize, color: effectiveText),
                if (icon != null) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: context.rf(12),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: effectiveText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
