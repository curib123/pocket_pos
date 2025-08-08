import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/View/Components/Custom/CustomButton.dart';
import 'package:pocketpos/View/Components/Custom/CustomFlatDropdown.dart';

class PaymentForm extends StatefulWidget {
  final void Function(String paymentMethod, File proofFile) onSubmit;
  final String? initialPaymentMethod;

  const PaymentForm({
    super.key,
    required this.onSubmit,
    this.initialPaymentMethod,
  });

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  String? selectedPaymentMethod;
  File? selectedProofFile;
  String? proofFileName;

  List<Map<String, dynamic>> paymentOptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPaymentMethods();

    if (widget.initialPaymentMethod != null) {
      selectedPaymentMethod = widget.initialPaymentMethod;
    }
  }

  Future<void> fetchPaymentMethods() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('payment_methods').select('name, instruction');

    setState(() {
      paymentOptions = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> _pickProofFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedProofFile = File(result.files.single.path!);
        proofFileName = result.files.single.name;
      });
    }
  }

  void _submit() {
    if (selectedPaymentMethod == null || selectedProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a method and upload proof."),
        ),
      );
      return;
    }

    widget.onSubmit(selectedPaymentMethod!, selectedProofFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialPaymentMethod == null ? "Payment Form" : "Edit Payment"),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : paymentOptions.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.creditCard, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "No payment methods available.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please try again later or contact support.",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: ListView(
            children: [
              /// 🔘 Payment Instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(LucideIcons.info, size: 17, color: Colors.black54),
                        SizedBox(width: 6),
                        Text(
                          "Payment Instructions",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    /// Mapped instructions
                    ...paymentOptions.map((method) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['name'],
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.025),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                method['instruction'],
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔽 Payment Method Dropdown
              CustomFlatDropdown<String>(
                label: "Payment Method",
                hint: "Select payment method",
                value: selectedPaymentMethod,
                items: paymentOptions.map((e) => e['name'] as String).toList(),
                prefixIcon: LucideIcons.wallet,
                itemBuilder: (val) => Text(val),
                onChanged: (val) {
                  setState(() {
                    selectedPaymentMethod = val;
                  });
                },
              ),

              const SizedBox(height: 10),

              /// 📎 Proof File Upload
              Text(
                "Got a screenshot or receipt? Upload it here",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 6),

              GestureDetector(
                onTap: _pickProofFile,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selectedProofFile != null
                          ? Image.file(
                        selectedProofFile!,
                        fit: BoxFit.cover,
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(LucideIcons.upload, size: 36, color: Colors.black45),
                          SizedBox(height: 6),
                          Text(
                            "Tap to upload Payment Proof/Receipt",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (selectedProofFile != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              "📎 Tap to change image",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              /// File name
              if (proofFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    proofFileName!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColor.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 24),

              /// ✅ Submit Button
              CustomButton(
                text: widget.initialPaymentMethod == null ? "Submit Payment" : "Save Changes",
                icon: LucideIcons.checkCircle,
                onPressed: _submit,
                isFilled: true,
                backgroundColor: AppColor.primary,
              ),
            ],
          ),
        )

      ),
    );
  }
}
