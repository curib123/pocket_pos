import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart' show Phoenix;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Helper/Database/PurchaseService.dart';
import 'package:nextpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:nextpos/View/Screen/Sub/PaymentForm.dart';

class VerificationPaymentScreen extends StatefulWidget {
  final VoidCallback onApproved;

  const VerificationPaymentScreen({
    super.key,
    required this.onApproved,
  });

  @override
  State<VerificationPaymentScreen> createState() =>
      _VerificationPaymentScreenState();
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
      isPending = true; // TODO: update from backend
      isLoading = false;
    });
  }

  Widget _statusBadge(
      String label, Color bgColor, Color fgColor, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: fgColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
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

  Widget _infoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColor.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofCard() {
    if (proofUrl == null) {
      return _infoCard(
        title: "Payment Proof",
        content: "No proof uploaded yet",
        icon: LucideIcons.imageOff,
      );
    }

    return GestureDetector(
      onTap: () => _openImagePreview(proofUrl!),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            proofUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey.shade100,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                    color: AppColor.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 200,
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
        ),
      ),
    );
  }

  void _openImagePreview(String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Hero(
                    tag: "proofImage",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          LucideIcons.imageOff,
                          color: Colors.grey.shade400,
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditFlow() {
    final PurchaseService purchaseService = PurchaseService();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentForm(
          initialPaymentMethod: paymentMethod,
          onSubmit: (String paymentMethod, File file) {
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
                    Navigator.of(context).pop();
                    try {
                      await purchaseService.sendPayment(
                        file: file,
                        paymentMethod: paymentMethod,
                      );
                      Future.delayed(const Duration(seconds: 1), () {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(LucideIcons.creditCard,
                        size: 64, color: AppColor.primary),
                    const SizedBox(height: 8),
                    Text(
                      "Payment Details",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    _infoCard(
                      title: "Payment Method",
                      content: paymentMethod ?? "Not provided",
                      icon: LucideIcons.wallet,
                    ),
                    const SizedBox(height: 16),

                    if (isPending)
                      _statusBadge(
                        "Pending Approval",
                        Colors.orange.shade100,
                        Colors.orange.shade800,
                        LucideIcons.clock,
                      ),
                    if (isPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "1-2 business days depending on traffic. We're reviewing your payment.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 20),
                    _proofCard(),
                  ],
                ),
              ),
            ),

            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Refresh",
                      icon: LucideIcons.refreshCw,
                      onPressed: widget.onApproved,
                      isFilled: true,
                      backgroundColor: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: "Edit",
                      icon: LucideIcons.edit2,
                      isFilled: false,
                      borderColor: AppColor.primary,
                      textColor: AppColor.primary,
                      onPressed: _openEditFlow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
