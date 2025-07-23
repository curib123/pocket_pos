import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/AppColor.dart';
import 'package:pocketpos/View/Components/ResponsiveText.dart';

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
  final bool isSlimmer; // 👈 NEW

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
    this.iconSize = 20,
    this.borderColor,
    this.isSlimmer = false, // 👈 DEFAULT
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
      padding: isSlimmer
          ? const EdgeInsets.symmetric(vertical: 6, horizontal: 10)
          : const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? (isSlimmer ? 36 : 45), // 👈 Adjust height if slim
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: buttonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: isSlimmer ? iconSize - 4 : iconSize, color: effectiveText),
            if (icon != null) const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: context.rf(isSlimmer ? 11 : 12), // 👈 Adjust font
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
