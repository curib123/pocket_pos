import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

Future<void> showQuantityEditDialog({
  required BuildContext context,
  required String title,
  required Function(double, double) onConfirm,
  double? initialQuantity,
  double? initialKiloQuantity,
}) async {
  final TextEditingController _quantityController =
  TextEditingController(text: (initialQuantity ?? 0).toString());
  final TextEditingController _kiloQuantityController =
  TextEditingController(text: (initialKiloQuantity ?? 0).toString());

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFFF9F6FF),
      surfaceTintColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 24),

            // Label + Field (Quantity)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Product Quantity",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildInputField(
              controller: _quantityController,
              hint: "Enter quantity (pcs)",
              icon: LucideIcons.package,
            ),
            const SizedBox(height: 20),

            // Label + Field (Kilo Quantity)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "kilograms Quantity (kg)",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildInputField(
              controller: _kiloQuantityController,
              hint: "Enter kilograms",
              icon: LucideIcons.dumbbell,
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD1C4E9)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color(0xFF6A1B9A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final double? qty =
                      double.tryParse(_quantityController.text);
                      final double? kiloQty =
                      double.tryParse(_kiloQuantityController.text);
                      if (qty != null && kiloQty != null) {
                        Navigator.of(context).pop();
                        onConfirm(qty, kiloQty);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter valid numbers'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.check),
                    label: const Text("Confirm"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E57C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
}) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    style: const TextStyle(fontSize: 16),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF7E57C2)),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
