import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Helper/Database/PurchaseService.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';

class VerificationScreen extends StatefulWidget {
  final VoidCallback onFreeTrial;
  final VoidCallback onPurchase;

  const VerificationScreen({
    super.key,
    required this.onFreeTrial,
    required this.onPurchase,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool showTrialButton = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    final purchaseService = PurchaseService();
    final details = await purchaseService.getPaymentDetails();

    final expirationDate = details?['expirationDate'];

    setState(() {
      showTrialButton = expirationDate == null || expirationDate.toString().trim().isEmpty;
      isLoading = false;
    });

    print('[VerificationScreen] showTrialButton: $showTrialButton');
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.badgeCheck,
                  size: 64,
                  color: AppColor.primary,
                ),
                const SizedBox(height: 24),

                Text(
                  "Welcome to nextpos!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  "Unlock powerful features to run your store smarter. "
                      "Start a free trial or purchase one-time to continue.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                if (showTrialButton) ...[
                  CustomButton(
                    text: "Start 7-Day Free Trial",
                    icon: LucideIcons.clock,
                    onPressed: widget.onFreeTrial,
                    isFilled: true,
                    backgroundColor: AppColor.primary,
                  ),
                  const SizedBox(height: 16),
                ],

                CustomButton(
                  text: "Purchase One-Time",
                  icon: LucideIcons.creditCard,
                  onPressed: widget.onPurchase,
                  isFilled: false,
                  borderColor: AppColor.primary,
                  textColor: AppColor.primary,
                ),

                const SizedBox(height: 48),
                Text(
                  "No subscriptions. Just one simple payment.\nTry it first, then decide.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
