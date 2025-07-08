import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Screens/Navigation/payment_form_screen.dart';
import 'package:paninda/View/Screens/Navigation/verification_screen.dart';

class HandlePaymentVerification extends StatelessWidget {
  final Map<String, dynamic> latestPayment;
  final Future<String?> paymentProofPublicUrl;

  const HandlePaymentVerification({
    super.key,
    required this.latestPayment,
    required this.paymentProofPublicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: VerificationStatusCard(
              isSuccess: true,
              showPrimaryButton: true,
              title: 'Payment Submitted',
              subtitleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Your payment has been submitted successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (latestPayment.isNotEmpty) ...[
                    _buildInfoRow('Method', latestPayment['payment_method']),
                    const SizedBox(height: 8),
                    _buildStatusBadge(latestPayment['payment_status']),
                    const SizedBox(height: 20),
                    FutureBuilder<String?>(
                      future: paymentProofPublicUrl,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return const Text(
                            'Failed to load payment proof.',
                            style: TextStyle(color: Colors.redAccent),
                          );
                        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return Column(
                            children: [
                              const Text(
                                'Payment Proof',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  snapshot.data!,
                                  height: 160,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const SizedBox(
                                      height: 160,
                                      width: 160,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error, size: 40, color: Colors.red),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        } else {
                          return const Text('No payment proof available.');
                        }
                      },
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No payment record found.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              statusIcon: LucideIcons.checkCircle,
              buttonIcon: _getButtonIcon(),
              buttonText: _getButtonText(),
              mainColor: AppColor.success,
              onPressed: () {
                Phoenix.rebirth(context);
              },
              showSecondButton: true,
              secondButtonColor: Colors.orange,
              secondButtonIcon: LucideIcons.edit,
              secondButtonText: 'Edit Payment',
              secondButtonOnPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentFormScreen(
                      isEdit: true,
                      initialMethod: latestPayment['payment_method'],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value?.toString() ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status?.toString() ?? 'N/A',
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getButtonText() {
    final status = latestPayment['payment_status']?.toString() ?? '';
    return (status == 'pending' || status == 'rejected') ? 'Refresh' : 'Continue';
  }

  IconData _getButtonIcon() {
    final status = latestPayment['payment_status']?.toString() ?? '';
    return (status == 'pending' || status == 'rejected')
        ? LucideIcons.refreshCcw
        : LucideIcons.arrowRight;
  }
}
