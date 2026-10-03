import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nextpos/View/Components/Custom/CustomButton.dart';
import 'package:nextpos/View/Components/Custom/CustomTextField.dart';

Future<void> showChangeBatchQtyDialog({
  required BuildContext context,
  required double initialQty,
  required Function(double newQty) onConfirm,
}) async {
  final TextEditingController qtyController =
  TextEditingController(text: initialQty.toString());

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.package, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Edit Batch Quantity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: qtyController,
                label: 'Enter new quantity',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      icon: LucideIcons.x,
                      isFilled: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: CustomButton(
                      text: 'Update',
                      onPressed: () {
                        final newQty = double.tryParse(qtyController.text.trim());
                        if (newQty != null) {
                          onConfirm(newQty);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid number')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
