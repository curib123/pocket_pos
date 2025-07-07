import 'package:flutter/material.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/PaymentGuideProvider.dart';
import 'package:provider/provider.dart';

class HandlePaymentGuide extends StatefulWidget {
  const HandlePaymentGuide({super.key});

  @override
  State<HandlePaymentGuide> createState() => _HandlePaymentGuideState();
}

class _HandlePaymentGuideState extends State<HandlePaymentGuide> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PaymentGuideProvider>(context, listen: false).loadGuides();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentGuideProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.success.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColor.success, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColor.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Loading
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          /// Error
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Error: ${provider.errorMessage}",
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),

          /// Payment Guides with Static Instruction
          if (!provider.isLoading && provider.errorMessage == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Added static instruction (always at the top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "• ",
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Send your payment to the provided account below. "
                              "After payment, please screenshot or capture the receipt and upload it here for verification.",
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.3,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Dynamic payment instructions from provider
                ...provider.guides.map(
                      (guide) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(
                            fontSize: 14.5,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            guide['instruction'],
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.3,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
