import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart' show Phoenix;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Database/PurchaseService.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Screen/Sub/PaymentForm.dart';

class VerificationPaymentScreen extends StatefulWidget {
  final VoidCallback onApproved;

  const VerificationPaymentScreen({
    super.key,
    required this.onApproved,
  });

  @override
  State<VerificationPaymentScreen> createState() => _VerificationPaymentScreenState();
}

class _VerificationPaymentScreenState extends State<VerificationPaymentScreen> {
  bool isLoading = true;
  String? paymentMethod;
  String? proofUrl;
  bool isPending = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() => isLoading = true);
    final purchaseService = PurchaseService();
    final details = await purchaseService.getPaymentDetails();

    setState(() {
      paymentMethod = details?['paymentMethod'];
      proofUrl = details?['paymentProofUrl'];
      isPending = true; // update from backend
      isLoading = false;
    });
  }

  Widget _statusBadge(String label, Color bgColor, Color fgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageWithPlaceholder(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 180,
        width: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColor.primary,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 180,
          color: Colors.grey.shade100,
          child: Center(
            child: Icon(
              LucideIcons.imageOff,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = 20.0;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.creditCard,
                    size: 64,
                    color: AppColor.primary,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Payment Details",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  if (paymentMethod != null)
                    Text(
                      "Method: $paymentMethod",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      "No payment method available",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),

                  if (isPending)
                    _statusBadge(
                      "Pending Approval",
                      Colors.orange.shade100,
                      Colors.orange.shade800,
                      LucideIcons.clock,
                    ),

                  if (isPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "1-2 business days, depends on traffic. We're reviewing your payment. Thanks for your patience!",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),


                  const SizedBox(height: 24),

                  if (proofUrl != null) _imageWithPlaceholder(proofUrl!)
                  else
                    Text(
                      "No payment proof uploaded yet.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 12),

// If you want the Edit button next to Refresh, wrap them in a Row:
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Refresh",
                          icon: LucideIcons.refreshCw,
                          onPressed: widget.onApproved,
                          isFilled: true,
                          backgroundColor: AppColor.primary,
                          height: 44,
                          iconSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: "Edit",
                          icon: LucideIcons.edit2,
                          onPressed: () {
                            // TODO: Add your edit logic here, e.g. navigate to edit screen
                            final PurchaseService purchaseService = PurchaseService();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentForm(
                                  initialPaymentMethod: paymentMethod,
                                  onSubmit: (String paymentMethod, File file) {
                                    // Wrap the actual submit inside a confirm dialog first
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => WillPopScope(
                                        onWillPop: () async => false,
                                        child: CustomConfirmDialog(
                                          title: "Confirm Payment Submission",
                                          content:
                                          "Are you sure you want to submit this payment using \"$paymentMethod\"?",
                                          onConfirm: () async {
                                            Navigator.of(context).pop(); // close dialog
                                            try {
                                              await purchaseService.sendPayment(
                                                file: file,
                                                paymentMethod: paymentMethod,
                                              );
                                              Future.delayed(Duration(seconds: 1),(){
                                                Phoenix.rebirth(context);
                                              });
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('❌ Failed to submit payment: $e'),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );

                          },
                          isFilled: false,
                          backgroundColor: Colors.transparent,
                          height: 44,
                          iconSize: 18,
                          textColor: AppColor.primary,
                          borderColor: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Divider(color: Colors.grey.shade300, thickness: 1),

                  const SizedBox(height: 14),

                  Text(
                    "Pro Tip: Upload a clear payment proof to speed up approval!",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
