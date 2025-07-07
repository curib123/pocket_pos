import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paninda/View/Components/Custom/handle_payment_guide.dart';
import 'package:paninda/View/Components/Custom/handle_payment_verification.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View_Model/PaymentProvider.dart';
import 'package:provider/provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final bool isEdit;
  final String? initialMethod;

  const PaymentFormScreen({
    super.key,
    this.isEdit = false,
    this.initialMethod,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _methods = [
    'GCash',
    'PayPal',
    'Bank Transfer',
    'Cash (Physical Payment)',
  ];
  String? _selectedMethod;
  File? _proofImage;

  Color _scaffoldBgColor = const Color(0xFFF0F2F5); // Default background color

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _proofImage = File(pickedFile.path));
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod == null) {
      _showSnackBar('Please select a payment method');
      return;
    }

    if (_proofImage == null) {
      _showSnackBar('Please upload your payment proof image');
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    final provider = Provider.of<PaymentProvider>(context, listen: false);
    try {
      await provider.submitPayment(
        paymentMethod: _selectedMethod!,
        proofImage: _proofImage!,
      );

      final Map<String, dynamic> latestPayment =
      provider.payments.isNotEmpty ? provider.payments.first : {};

      final paymentProofPublicUrl = provider.getLatestPaymentProofUrl();

      _showSnackBar("Payment submitted successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HandlePaymentVerification(
            latestPayment: latestPayment,
            paymentProofPublicUrl: paymentProofPublicUrl,
          ),
        ),
      );
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  void _showSnackBar(String message) {
    setState(() {
      if (message.toLowerCase().contains("error")) {
        _scaffoldBgColor = Colors.red.shade50;
      } else {
        _scaffoldBgColor = Colors.green.shade50;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    // Auto-reset background after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scaffoldBgColor = const Color(0xFFF0F2F5);
        });
      }
    });
  }

  Widget _buildPaymentFormCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Payment Method',
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
              ),
              value: _selectedMethod,
              items: _methods
                  .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMethod = value),
              validator: (value) =>
              value == null ? 'Select a payment method' : null,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: AppColor.success.withOpacity(0.4)),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _proofImage!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file,
                          size: 36,
                          color: AppColor.success.withOpacity(0.7)),
                      const SizedBox(height: 12),
                      Text(
                        "Tap here to upload your payment proof",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: isLoading ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      widget.isEdit
                          ? Icons.edit
                          : Icons.check_circle,
                      color: AppColor.surface,
                      size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEdit
                        ? "Update Payment"
                        : "Submit Payment",
                    style: const TextStyle(
                        fontSize: 16, color: AppColor.surface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<PaymentProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child:
          const Icon(Icons.arrow_back_ios_new, color: AppColor.success),
        ),
        title: Text(
          widget.isEdit ? "Edit Payment" : "Submit Payment",
          style: const TextStyle(
              color: AppColor.success, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColor.surface,
        elevation: 2,
      ),
      backgroundColor: _scaffoldBgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            HandlePaymentGuide(),
            const SizedBox(height: 28),
            _buildPaymentFormCard(isLoading),
          ],
        ),
      ),
    );
  }
}
