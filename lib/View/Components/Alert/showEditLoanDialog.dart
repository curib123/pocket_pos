import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomTextField.dart';

Future<void> showEditLoanDialog({
  required BuildContext context,
  required String productId,
  required String borrowerName,
  required DateTime loanDate,
  required int currentQuantity,
  required double currentPrice,
  required String currentBorrowerName,
}) async {
  final formKey = GlobalKey<FormState>();
  final quantityController = TextEditingController(text: currentQuantity.toString());
  final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
  final borrowerController = TextEditingController(text: currentBorrowerName);
  bool isLoading = false;

  await showDialog(
    context: context,
    barrierDismissible: !isLoading,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Text(
            textAlign: TextAlign.center,
            'Edit Loan',
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
              children: [
                CustomTextField(
                  label: 'Borrower Name',
                  controller: borrowerController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter borrower name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Quantity',
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                    final q = int.tryParse(val);
                    if (q == null || q <= 0) return 'Quantity must be a positive integer';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Price',
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter price';
                    final p = double.tryParse(val);
                    if (p == null || p < 0) return 'Price must be zero or more';
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
                Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    return CustomButton(
                      text: isLoading ? 'Saving...' : 'Save',
                      isDisabled: isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => isLoading = true);

                        final newQuantity = int.parse(quantityController.text.trim());
                        final newPrice = double.parse(priceController.text.trim());
                        final newBorrowerName = borrowerController.text.trim();

                        try {
                          await productProvider.editLoanForProduct(
                            productId: productId,
                            borrowerName: borrowerName,
                            loanDate: loanDate,
                            newQuantity: newQuantity,
                            newPrice: newPrice,
                            newBorrowerName: newBorrowerName,
                            track: true,
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Loan updated successfully')),
                          );
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $e')),
                          );
                        }
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
