import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: icon != null
            ? Icon(icon, size: 16, color: Colors.white) // smaller icon
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13, // smaller text
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10), // smaller vertical padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // slightly smaller radius
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
        ),
      ),
    );
  }
}
