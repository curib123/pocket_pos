import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mobile_pos_inventory/View/Components/ResponsiveText.dart'; // ✅ Responsive Text

class CustomNotificationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final VoidCallback? onConfirm;
  final String type; // success, error, warning

  const CustomNotificationDialog({
    Key? key,
    required this.title,
    required this.content,
    this.buttonText = "OK",
    this.onConfirm,
    this.type = "success",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pick icon and color based on type
    IconData iconData;
    Color color;

    switch (type) {
      case 'error':
        iconData = LucideIcons.xCircle;
        color = Colors.red;
        break;
      case 'warning':
        iconData = LucideIcons.alertTriangle;
        color = Colors.orange.shade800;
        break;
      default:
        iconData = LucideIcons.checkCircle;
        color = Colors.teal;
    }

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Bounce(
                duration: const Duration(milliseconds: 600),
                child: Icon(iconData, size: 48, color: color),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(22), // ✅ Responsive title
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 150),
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(16), // ✅ Responsive content
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (onConfirm != null) onConfirm!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: context.rf(15), // ✅ Responsive button text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
