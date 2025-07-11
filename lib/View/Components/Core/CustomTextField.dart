import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/Helper/AppColor.dart';
import 'package:mobile_pos_inventory/View/Components/Core/ResponsiveText.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText; // Added hintText parameter
  final TextEditingController controller;
  final bool obscure;
  final String? Function(String?)? validator;
  final bool isObscure;
  final VoidCallback? toggleObscure;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscure = false,
    this.validator,
    this.isObscure = false,
    this.toggleObscure,
  });

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,  // set hintText here
      labelStyle: TextStyle(
        color: AppColor.textSecondary,
        fontSize: context.rf(14), // Responsive font size
      ),
      filled: true,
      fillColor: AppColor.primary.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColor.primary.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      suffixIcon: obscure
          ? IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_off : Icons.visibility,
          color: AppColor.textSecondary,
        ),
        onPressed: toggleObscure,
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure && isObscure,
        validator: validator,
        style: TextStyle(
          color: AppColor.textPrimary,
          fontSize: context.rf(14), // Responsive font size
        ),
        decoration: _inputDecoration(context), // pass context for rf()
      ),
    );
  }
}
