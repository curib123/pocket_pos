import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/View/Components/ResponsiveText.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFilled;
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
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackground =
        backgroundColor ?? (isFilled ? AppColor.primary : Colors.transparent);
    final Color effectiveText =
        textColor ?? (isFilled ? AppColor.surface : AppColor.primary);

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveText,
      elevation: isFilled ? 2 : 0,
      side: isFilled
          ? null
          : BorderSide(color: effectiveText.withOpacity(0.7), width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: iconSize, color: effectiveText),
            if (icon != null) const SizedBox(width: 8),
            Flexible( // ✅ Prevents overflow
              child: Text(
                text,
                overflow: TextOverflow.ellipsis, // ✅ Ellipsis if too long
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: context.rf(15),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.6,
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
