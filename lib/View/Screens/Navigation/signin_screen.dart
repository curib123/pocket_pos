import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:paninda/View/Components/Alert/custom_confirm_dialog.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/LinkOpener.dart';
import 'package:paninda/View/Screens/Navigation/verification_screen.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Screens/Navigation/signup_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration.zero, () async {
      final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);
      await authPaymentProvider.fetchTrialInfo();
    });

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
                    child: Consumer2<AuthPaymentProvider,TabProvider>(
                      builder: (context, authPaymentProvider,tabProvider, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.store, size: 48, color: AppColor.primary),
                          const SizedBox(height: 16),
                          const Text(
                            "Sign In to Paninda",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Welcome back! Please log in.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: AppColor.textSecondary),
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
                            label: "Password",
                            icon: LucideIcons.lock,
                            obscureText: !_isPasswordVisible,
                            isPasswordField: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authPaymentProvider.isLoading
                                  ? null
                                  : () async {
                                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomConfirmDialog(
                                      icon: Icons.warning_amber_rounded,
                                      iconColor: Colors.orange,
                                      title: "Missing Fields",
                                      content: "Please fill in both email and password.",
                                      cancelText: "Close",
                                      confirmText: "OK",
                                      onConfirm: () {},
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await authPaymentProvider.signIn(
                                    emailController.text,
                                    passwordController.text,
                                  );

                                  if (!context.mounted) return;

                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomConfirmDialog(
                                      icon: Icons.check_circle,
                                      iconColor: Colors.green,
                                      title: "Login Successful!",
                                      content: "You have successfully logged into your account.",
                                      cancelText: "Close",
                                      confirmText: "Continue",
                                      onConfirm: () async {
                                        final isActivated = await authPaymentProvider.checkActivationStatus();

                                        if (isActivated) {
                                          final isTrial = await authPaymentProvider.checkTrialStatus();
                                          final isActive = await authPaymentProvider.checkActiveStatus();

                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Scaffold(
                                                backgroundColor: Colors.grey.shade100,
                                                body: Center(
                                                  child: VerificationStatusCard(
                                                    isSuccess: true,
                                                    title: isTrial
                                                        ? 'Free Trial Activated'
                                                        : (isActive ? 'Fully Account Activated' : 'Account Status Unknown'),
                                                    subtitleWidget: Text(
                                                      isTrial
                                                          ? 'Welcome aboard! You’re now on a Free Trial.\nEnjoy exploring all features during your trial period.'
                                                          : (isActive
                                                          ? 'Thank you for your payment!\nYour account is now fully activated and ready to use.'
                                                          : 'We couldn’t verify your account status.\nPlease contact support.'),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    statusIcon: LucideIcons.checkCircle,
                                                    buttonIcon: LucideIcons.arrowRight,
                                                    buttonText: 'Get Started',
                                                    mainColor: const Color(0xFF4CAF50),
                                                    onPressed: () async {
                                                      await authPaymentProvider.setTrialStatus(false);
                                                      checkIfTrialExpired(context);
                                                      await tabProvider.setFirstTimeFlag(false);
                                                      if (!tabProvider.isFirstTime) {
                                                        Phoenix.rebirth(context);
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        else {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => Scaffold(
                                                backgroundColor: Colors.grey.shade100,
                                                body: Center(
                                                  child: VerificationStatusCard(
                                                    isSuccess: false,
                                                    title: 'Activation Failed',
                                                    subtitleWidget: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          "We couldn’t verify your payment.",
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 14),
                                                        Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.amber.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Icon(LucideIcons.wallet, color: Colors.amber, size: 22),
                                                              const SizedBox(width: 10),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    const Text(
                                                                      "Need Full Access?",
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.w700,
                                                                        fontSize: 14,
                                                                        color: Colors.black87,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 8),
                                                                    const Text(
                                                                      "Please message us via our Facebook page:",
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: Colors.black87,
                                                                        height: 1.4,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 10),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: SelectableText(
                                                                            "📩 Curib Tech\n💬 Message: Mobile Paninda Payment",
                                                                            style: const TextStyle(
                                                                              fontSize: 12,
                                                                              color: Colors.blueAccent,
                                                                              fontWeight: FontWeight.w600,
                                                                              height: 1.4,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        IconButton(
                                                                          icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent),
                                                                          tooltip: "Copy",
                                                                          onPressed: () {
                                                                            Clipboard.setData(const ClipboardData(
                                                                              text: "Curib Tech - Mobile Paninda POS and Inventory App Payment",
                                                                            ));
                                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                                              const SnackBar(
                                                                                content: Text("Copied to clipboard!"),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    statusIcon: LucideIcons.xCircle,
                                                    buttonIcon: LucideIcons.creditCard,
                                                    buttonText: 'Message Us on Facebook',
                                                    mainColor: const Color(0xFFF44336),
                                                    showPrimaryButton: false,
                                                    showSecondButton: true,
                                                    onPressed: () {
                                                      LinkOpener.openLink(
                                                        context,
                                                        "https://www.facebook.com/profile.php?id=61577201312987",
                                                      );
                                                    },
                                                    secondButtonIcon: LucideIcons.gift,
                                                    secondButtonText: 'Start Free Trial',
                                                    secondButtonColor: Colors.blueGrey,
                                                    secondButtonOnPressed: () async {
                                                      await authPaymentProvider.setTrialStatus(true);
                                                      await authPaymentProvider.fetchTrialInfo();
                                                      await tabProvider.setFirstTimeFlag(false);
                                                      if (!tabProvider.isFirstTime) {
                                                        Phoenix.rebirth(context);
                                                      }
                                                    },
                                                    secondButtonSubtitle: 'Enjoy limited access for 7 days without payment.',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (_) => CustomConfirmDialog(
                                      icon: Icons.error_outline,
                                      iconColor: Colors.redAccent,
                                      title: "Sign In Failed!",
                                      content: "Incorrect email or password. Please try again.",
                                      cancelText: "Close",
                                      confirmText: "Retry",
                                      onConfirm: () {},
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                              child: authPaymentProvider.isLoading
                                  ? const CircularProgressIndicator(color: AppColor.surface)
                                  : const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.surface,
                                ),
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                        },
                        child: const Text(
                          "Sign Up",
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        filled: true,
        fillColor: AppColor.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
          borderSide: const BorderSide(color: AppColor.textSecondary, width: 1),
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
