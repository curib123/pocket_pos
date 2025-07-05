import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class VerificationStatusCard extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String subtitle;
  final IconData statusIcon;
  final IconData buttonIcon;
  final String buttonText;
  final Color mainColor;
  final VoidCallback onPressed;
  final Duration animationDuration;

  const VerificationStatusCard({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.subtitle,
    required this.statusIcon,
    required this.buttonIcon,
    required this.buttonText,
    required this.mainColor,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            ZoomIn(
              duration: animationDuration,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      mainColor.withOpacity(0.2),
                      mainColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 72,
                  color: mainColor,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            FadeIn(
              duration: animationDuration,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Subtitle
            FadeInUp(
              duration: animationDuration,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),

            // Button
            FadeInUp(
              duration: animationDuration,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: BounceInDown(
                  child: Icon(buttonIcon, color: Colors.white),
                  duration: const Duration(milliseconds: 800),
                ),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
