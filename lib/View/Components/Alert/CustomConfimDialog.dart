import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/ResponsiveText.dart';

class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? customContent;
  final String cancelText;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final bool? showThirdButton;
  final IconData? thirdButtonIcon;
  final String? thirdButtonText;
  final VoidCallback? onThirdButton;
  final bool? isPop;

  const CustomConfirmDialog({
    Key? key,
    required this.title,
    this.content,
    this.customContent,
    required this.onConfirm,
    this.onCancel,
    this.cancelText = "Cancel",
    this.confirmText = "Confirm",
    this.icon,
    this.iconColor,
    this.thirdButtonText,
    this.onThirdButton,
    this.showThirdButton = false,
    this.thirdButtonIcon,
    this.isPop = true,
  })  : assert(content != null || customContent != null,
  'Either content or customContent must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColor.surface,
      surfaceTintColor: AppColor.surface,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null)
                    Icon(icon, size: 48, color: iconColor ?? AppColor.primary),
                  if (icon != null) const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.rf(22),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (customContent != null)
                    customContent!
                  else if (content != null)
                    Text(
                      content!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.rf(16),
                        color: AppColor.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 28),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              borderColor: AppColor.textSecondary,
                              text: cancelText,
                              isFilled: false,
                              onPressed: () {
                                if (onCancel != null) onCancel!();
                                Navigator.pop(context);
                              },
                              isSlimmer: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              backgroundColor: AppColor.primary,
                              text: confirmText,
                              onPressed: () {
                                onConfirm();
                               isPop == true ? Navigator.pop(context) : null;
                              },
                              isFilled: true,
                              isSlimmer: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      showThirdButton!
                          ? CustomButton(
                        text: thirdButtonText ?? '',
                        backgroundColor: AppColor.secondarySurface,
                        icon: thirdButtonIcon,
                        textColor: AppColor.textPrimary,
                        isFilled: true,
                        isSlimmer: true,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onThirdButton!();
                        },
                      )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),

            // ✖️ Exit icon in the top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                splashRadius: 20,
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
