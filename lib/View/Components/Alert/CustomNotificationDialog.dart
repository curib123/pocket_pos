import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/ResponsiveText.dart'; // ✅ Responsive Text

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
    // 🎨 Pick icon and color from AppColor based on type
    IconData iconData;
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (type) {
      case 'error':
        iconData = LucideIcons.xCircle;
        backgroundColor = AppColor.errorBackground;
        textColor = AppColor.errorText;
        iconColor = AppColor.error;
        break;
      case 'warning':
        iconData = LucideIcons.alertTriangle;
        backgroundColor = AppColor.warningBackground;
        textColor = AppColor.warningText;
        iconColor = AppColor.warning;
        break;
      default:
        iconData = LucideIcons.checkCircle;
        backgroundColor = AppColor.surface;
        textColor = AppColor.textPrimary;
        iconColor = AppColor.primary;
    }

    return Dialog(
      backgroundColor: AppColor.surface,
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
                child: Icon(iconData, size: 48, color: iconColor),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.rf(22),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColor.textPrimary,
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
                    fontSize: context.rf(16),
                    color: AppColor.textSecondary,
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
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: context.rf(15),
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
