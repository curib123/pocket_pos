import 'package:flutter/material.dart';

class CustomPillToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const CustomPillToggle({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? color : Colors.transparent;
    final textColor = isSelected ? Colors.white : color;
    final iconColor = isSelected ? Colors.white : color;
    final borderColor = color;
    final shadowColor = color.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Shrink padding if constrained tightly
          final isTight = constraints.maxWidth < 100;
          final horizontalPadding = isTight ? 6.0 : 12.0;
          final verticalPadding = isTight ? 6.0 : 10.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
                  : [],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: iconColor,
                    size: isTight ? 14 : 18,
                  ),
                  SizedBox(width: isTight ? 4 : 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isTight ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
