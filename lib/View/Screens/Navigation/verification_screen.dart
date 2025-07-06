import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

class VerificationStatusCard extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final Widget subtitleWidget;
  final IconData statusIcon;
  final IconData buttonIcon;
  final String buttonText;
  final Color mainColor;
  final VoidCallback onPressed;
  final Duration animationDuration;

  // Optional Second Button (Reusable)
  final IconData? secondButtonIcon;
  final String? secondButtonText;
  final Color? secondButtonColor;
  final VoidCallback? secondButtonOnPressed;
  final String? secondButtonSubtitle;

  // New parameters for button visibility
  final bool showPrimaryButton;
  final bool showSecondButton;

  const VerificationStatusCard({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.subtitleWidget,
    required this.statusIcon,
    required this.buttonIcon,
    required this.buttonText,
    required this.mainColor,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.secondButtonIcon,
    this.secondButtonText,
    this.secondButtonColor,
    this.secondButtonOnPressed,
    this.secondButtonSubtitle,
    this.showPrimaryButton = true,
    this.showSecondButton = true,
  });

  @override
  State<VerificationStatusCard> createState() => _VerificationStatusCardState();
}

class _VerificationStatusCardState extends State<VerificationStatusCard> {
  @override
  void initState() {
    super.initState();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final loanProvider = Provider.of<LoanProvider>(context, listen: false);

    Future.delayed(Duration.zero, () async {
      await productProvider.syncProductsWithServer();
      await productProvider.insertOrUpdateProductsToDatabase();
      await loanProvider.syncLoansWithServer();
      await loanProvider.insertOrUpdateLoansToDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeIn(
              duration: widget.animationDuration,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.mainColor.withOpacity(0.2),
                      widget.mainColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.statusIcon,
                  size: 60,
                  color: widget.mainColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeIn(
              duration: widget.animationDuration,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.mainColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            FadeIn(
              duration: widget.animationDuration,
              child: widget.subtitleWidget,
            ),
            const SizedBox(height: 28),
            FadeIn(
              duration: widget.animationDuration,
              child: Column(
                children: [
                  if (widget.showPrimaryButton) ...[
                    ElevatedButton.icon(
                      onPressed: widget.onPressed,
                      icon: Icon(widget.buttonIcon, color: Colors.white, size: 20),
                      label: Text(
                        widget.buttonText,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.mainColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],

                  if (widget.showSecondButton &&
                      !widget.isSuccess &&
                      widget.secondButtonIcon != null &&
                      widget.secondButtonText != null &&
                      widget.secondButtonColor != null &&
                      widget.secondButtonOnPressed != null) ...[
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: widget.secondButtonOnPressed,
                      icon: Icon(widget.secondButtonIcon, color: Colors.white, size: 20),
                      label: Text(
                        widget.secondButtonText!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.secondButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                    ),
                    if (widget.secondButtonSubtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.secondButtonSubtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
