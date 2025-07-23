import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomTextField.dart';

Future<void> showPayAllLoansDialog({
  required BuildContext context,
  required String borrowerName,
  required double total,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: total.toStringAsFixed(2));
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
          title: Text(
            'Pay All Loans ',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Amount to Pay',
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final v = double.tryParse(val);
                    if (v == null) return 'Invalid number';
                    if (v <= 0) return 'Must be greater than zero';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total due: ${total.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                   SizedBox(height: 5,),
                   CustomButton(text: "Use Full Amount",  onPressed: (){
                     controller.text = total.toStringAsFixed(2 );
                   },
                   isSlimmer: true,
                     isFilled: false,
                   ),
                  ],
                )
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
                Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    return CustomButton(
                      text: isLoading ? 'Processing...' : 'Pay All',
                      isDisabled: isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;


                        final amount = double.parse(controller.text.trim());
                        Navigator.pop(context);
                        await showDialog(
                          context: context,
                          builder: (context) => CustomConfirmDialog(
                            icon: LucideIcons.checkCircle2,
                            title: 'Confirm Payment',
                            content: 'Are you sure you want to pay ₱${amount.toStringAsFixed(2)} for "$borrowerName"?',
                            onConfirm: () async {
                              setState(() => isLoading = true);
                              try {
                                await productProvider.payAllLoansByBorrower(
                                  borrowerName,
                                  amount,
                                  track: true,
                                );
                                Navigator.of(context).pop(); // Close current dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ Paid ${amount.toStringAsFixed(2)} for "$borrowerName"'),
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
