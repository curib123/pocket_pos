import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Alert/custom_confirm_dialog.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Screens/Navigation/signin_screen.dart';

class SignupProvider with ChangeNotifier {
  bool isLoading = false;

  Future<void> signup({
    required String email,
    required String password,
    required String storeName,
    required String ownerName,
  }) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    isLoading = false;
    notifyListeners();

    debugPrint('Signed Up: $email, $password, $storeName, $ownerName');
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storeNameController = TextEditingController();
  final ownerNameController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    storeNameController.dispose();
    ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColor.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Consumer<AuthPaymentProvider>(
                      builder: (context, provider, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.store,
                            size: 48,
                            color: AppColor.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Sign Up to Paninda",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Create your store account below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColor.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildInputField(
                            controller: emailController,
                            label: "Email Address",
                            icon: LucideIcons.mail,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: passwordController,
                            label: "Create Password",
                            icon: LucideIcons.lock,
                            obscureText: !_isPasswordVisible,
                            isPasswordField: true,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: storeNameController,
                            label: "Store Name",
                            icon: LucideIcons.store,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: ownerNameController,
                            label: "Your Name",
                            icon: LucideIcons.user,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                if (emailController.text.isEmpty ||
                                    passwordController.text.isEmpty ||
                                    storeNameController.text.isEmpty ||
                                    ownerNameController.text.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomConfirmDialog(
                                      icon: Icons.warning_amber_rounded,
                                      iconColor: Colors.orange,
                                      title: "Incomplete Fields",
                                      content:
                                      "Please fill out all fields before proceeding.",
                                      cancelText: "Close",
                                      confirmText: "OK",
                                      onConfirm: () {},
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final result =
                                  await provider.signUp(
                                    email: emailController.text,
                                    password: passwordController.text,
                                    storeName:
                                    storeNameController.text,
                                    ownerName: ownerNameController.text,
                                  );

                                  if (!context.mounted) return;

                                  if (result != null) {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          CustomConfirmDialog(
                                            icon: Icons.check_circle,
                                            iconColor: Colors.green,
                                            title:
                                            "Store Created Successfully!",
                                            content:
                                            "Please sign in to continue.",
                                            cancelText: "Close",
                                            confirmText: "Go to Sign In",
                                            onConfirm: () {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                  const SigninScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          CustomConfirmDialog(
                                            icon: Icons.error_outline,
                                            iconColor: Colors.redAccent,
                                            title: "Sign Up Failed!",
                                            content:
                                            "Unexpected error occurred. Please try again.",
                                            cancelText: "Close",
                                            confirmText: "Retry",
                                            onConfirm: () {},
                                          ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;

                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomConfirmDialog(
                                      icon: Icons.error_outline,
                                      iconColor: Colors.redAccent,
                                      title: "Sign Up Failed!",
                                      content:
                                      "An error occurred. Please check your internet or try again.",
                                      cancelText: "Close",
                                      confirmText: "Retry",
                                      onConfirm: () {},
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                padding:
                                const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: provider.isLoading
                                  ? const CircularProgressIndicator(
                                color: AppColor.surface,
                              )
                                  : const Text(
                                "Create My Store",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.surface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SigninScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isPasswordField = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColor.accent, size: 22),
        labelText: label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AppColor.background,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppColor.textSecondary, width: 1),
        ),
        suffixIcon: isPasswordField
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
            color: AppColor.accent,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
      ),
    );
  }
}
