import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:provider/provider.dart';

class VerificationStatusCard extends StatefulWidget {
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
  State<VerificationStatusCard> createState() => _VerificationStatusCardState();
}



class _VerificationStatusCardState extends State<VerificationStatusCard> {

  @override
  void initState() {
    // TODO: implement initState
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
              duration: widget.animationDuration,
              child: Container(
                padding: const EdgeInsets.all(24),
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
                  size: 72,
                  color: widget.mainColor,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            FadeIn(
              duration: widget.animationDuration,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.mainColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),

            // Subtitle
            FadeInUp(
              duration: widget.animationDuration,
              child: Text(
                widget.subtitle,
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
              duration: widget.animationDuration,
              child: ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: BounceInDown(
                  child: Icon(widget.buttonIcon, color: Colors.white),
                  duration: const Duration(milliseconds: 800),
                ),
                label: Text(widget.buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.mainColor,
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
