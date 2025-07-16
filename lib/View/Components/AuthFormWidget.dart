import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Helper/AppColor.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomButton.dart';
import 'package:mobile_stock_inventory/View/Components/Custom/CustomTextField.dart';
import 'package:mobile_stock_inventory/View/Components/ResponsiveText.dart';

class AuthFormWidget extends StatefulWidget {
  final void Function({
  required String storeName,
  required String ownerName,
  required String email,
  required String password,
  required bool isSignUp,
  }) onSubmit;

  final bool isSignUp;
  final VoidCallback toggleMode;

  const AuthFormWidget({
    super.key,
    required this.onSubmit,
    required this.isSignUp,
    required this.toggleMode,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscure = true;

  void _trySubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        storeName: _storeNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        isSignUp: widget.isSignUp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.isSignUp;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 60,
            color: AppColor.primary,
          ),
          const SizedBox(height: 12),
          // Inside AuthFormWidget build method

          if (isSignUp)
            CustomTextField(
              label: "Store Name",
              controller: _storeNameController,
              validator: (val) => val!.isEmpty ? "Enter store name" : null,
              prefixIcon: Icon(Icons.store),
            ),

          if (isSignUp)
            CustomTextField(
              label: "Owner Name",
              controller: _ownerNameController,
              validator: (val) => val!.isEmpty ? "Enter owner name" : null,
              prefixIcon: Icon(Icons.person),
            ),

          CustomTextField(
            label: "Email",
            controller: _emailController,
            validator: (val) =>
            val != null && val.contains('@') ? null : "Enter valid email",
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(Icons.email),
          ),

          CustomTextField(
            label: "Password",
            controller: _passwordController,
            obscure: true,
            isObscure: _isObscure,
            toggleObscure: () => setState(() => _isObscure = !_isObscure),
            validator: (val) =>
            val != null && val.length >= 6 ? null : "Min 6 characters",
            prefixIcon: Icon(Icons.lock),
          ),

          if (isSignUp)
            CustomTextField(
              label: "Confirm Password",
              controller: _confirmPasswordController,
              obscure: true,
              isObscure: _isObscure,
              toggleObscure: () => setState(() => _isObscure = !_isObscure),
              validator: (val) =>
              val == _passwordController.text ? null : "Passwords don't match",
              prefixIcon: Icon(Icons.lock_outline),
            ),


          CustomButton(
            text: isSignUp ? "Sign Up" : "Sign In",
            onPressed: _trySubmit,
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: widget.toggleMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isSignUp
                          ? "Already have an account? "
                          : "Don't have an account? ",
                      style: TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: context.rf(13), // ✅ Responsive
                      ),
                    ),
                    WidgetSpan(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: context.rf(13), // ✅ Responsive
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          child: Text(isSignUp ? "Sign In" : "Sign Up"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
