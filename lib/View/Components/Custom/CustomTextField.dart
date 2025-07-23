import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/AppColor.dart';
import 'package:pocketpos/View/Components/ResponsiveText.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool isObscure;
  final VoidCallback? toggleObscure;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final Widget? prefixIcon;
  final String? helperText;

  // NEW: optional focusNode param (nullable)
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.obscure = false,
    this.isObscure = false,
    this.toggleObscure,
    this.isRequired = false,
    this.onChanged,
    this.readOnly = false,
    this.prefixIcon,
    this.helperText,
    this.focusNode, // add here
  });

  InputDecoration _buildDecoration(BuildContext context) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(
        color: AppColor.textSecondary,
        fontSize: context.rf(14),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColor.textSecondary.withOpacity(0.3),
        fontSize: context.rf(13),
      ),
      helperText: helperText,
      helperStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontStyle: FontStyle.italic,
        overflow: TextOverflow.visible,
      ),
      helperMaxLines: 3,
      filled: true,
      fillColor: AppColor.secondarySurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColor.primary.withOpacity(0.8),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
      prefixIcon: prefixIcon,
      prefixIconColor: AppColor.primary.withOpacity(0.6),
      suffixIcon: obscure
          ? IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_off : Icons.visibility,
          color: AppColor.primary.withOpacity(0.6),
        ),
        onPressed: toggleObscure,
      )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure && isObscure,
        validator: validator,
        onChanged: onChanged,
        readOnly: readOnly,
        focusNode: focusNode, // <-- pass the focusNode here
        style: TextStyle(
          color: AppColor.textPrimary,
          fontSize: context.rf(14),
        ),
        decoration: _buildDecoration(context),
      ),
    );
  }
}
