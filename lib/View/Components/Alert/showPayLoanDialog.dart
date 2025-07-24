import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/Provider/LoanProvider.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomTextField.dart';

Future<void> showPayLoanDialog({
  required BuildContext context,
  required String productId,
  required String borrowerName,
  required double maxPayableAmount,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: maxPayableAmount.toStringAsFixed(2));
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: !isLoading,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            'Pay Loan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max payable: ${maxPayableAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Amount to Pay',
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final v = double.tryParse(val);
                    if (v == null) return 'Invalid number';
                    if (v <= 0) return 'Must be greater than zero';
                    if (v > maxPayableAmount) return 'Cannot exceed max due amount';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancel',
                  isFilled: false,
                  isDisabled: isLoading,
                  onPressed: () => Navigator.of(context).pop(),
                  width: 100,
                ),
                const SizedBox(width: 12),
                Consumer<LoanProvider>(
                  builder: (context, loanProvider, _) {
                    return CustomButton(
                      text: isLoading ? 'Processing...' : 'Pay',
                      isDisabled: isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final amount = double.parse(controller.text.trim());
                        await showDialog(
                          context: context,
                          builder: (context) => CustomConfirmDialog(
                            icon: LucideIcons.checkCircle2,
                            title: 'Confirm Loan Payment',
                            content: 'Proceed to pay ${amount.toStringAsFixed(2)} for "$borrowerName"?',
                            onConfirm: () async {
                              try {
                                setState(() => isLoading = true);
                                await loanProvider.payLoanForProduct(
                                  productId: productId,
                                  borrowerName: borrowerName,
                                  amount: amount,
                                  track: true,
                                );
                                Navigator.of(context).pop(); // Close payment dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Payment of ${amount.toStringAsFixed(2)} successful'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green[600],
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } catch (e) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Payment failed: $e'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.red[600],
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        );


                      },
                      width: 100,
                    );
                  },
                ),
              ],
            )
          ],
        );
      });
    },
  );
}
