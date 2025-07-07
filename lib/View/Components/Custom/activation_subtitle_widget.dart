import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ActivationSubtitleWidget extends StatelessWidget {
  const ActivationSubtitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "We couldn’t confirm your payment yet.",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.wallet, color: Colors.amber, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Unlock Lifetime Access",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "1. Message us on Facebook.\n"
                    "2. Or tap 'Unlock Lifetime Use Now' to pay.\n"
                    "3. We’ll activate your account after payment.",
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      "FB Page : Curib Tech\n💬 Mobile Paninda Lifetime Access",
                      style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent),
                    tooltip: "Copy",
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                        text: "Curib Tech - Mobile Paninda POS Lifetime Access Payment",
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Payment info copied!")),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
