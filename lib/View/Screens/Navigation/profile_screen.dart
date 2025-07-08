import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:paninda/View/Components/Alert/custom_confirm_dialog.dart';
import 'package:paninda/View/Components/Custom/activation_subtitle_widget.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Screens/Navigation/payment_form_screen.dart';
import 'package:paninda/View_Model/PaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:provider/provider.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/HelperClass/responsive_text.dart';
import 'package:paninda/View_Model/CurrencyProvider.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? accountEmail;
  String? storeName;
  String? ownerName;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final userDetails = await Provider.of<AuthPaymentProvider>(context, listen: false).readUserDetails();
    setState(() {
      accountEmail = userDetails['email'] ?? 'Unknown';
      storeName = userDetails['storeName'] ?? 'Unknown Store';
      ownerName = userDetails['ownerName'] ?? 'Unknown Owner';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<CurrencyProvider>(context, listen: false).loadCurrency();
  }

  @override
  Widget build(BuildContext context) {
    const String aboutDev = "CuribTech Software Development Services";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColor.primary.withOpacity(0.85),
                        AppColor.primary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(LucideIcons.user, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName ?? 'Loading...',
                              style: TextStyle(
                                fontSize: getResponsiveFontSize(context, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ownerName ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Trial Info & Payment Section
              FutureBuilder<Map<String, dynamic>?>(
                future: Provider.of<AuthPaymentProvider>(context, listen: false).getTrialInfoOffline(),
                builder: (context, snapshot) {
                  final trialInfo = snapshot.data;

                  if (snapshot.connectionState == ConnectionState.done && trialInfo != null) {
                    if (trialInfo['isTrial'] == true) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.badgePercent, color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Your free trial has ${trialInfo['remainingDays']} day(s) remaining.",
                                        style: TextStyle(
                                          fontSize: getResponsiveFontSize(context, 12),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ActivationSubtitleWidget(),
                                const SizedBox(height: 12),
                                Consumer3<AuthPaymentProvider, TabProvider, PaymentProvider>(
                                  builder: (context, authPaymentProvider, tabProvider, paymentProvider, _) {
                                    return FadeInUp(
                                      duration: const Duration(milliseconds: 500),
                                      child: CustomButton(
                                        color: AppColor.success,
                                        label: "Unlock Lifetime Access Now",
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => FadeInDown(
                                              duration: const Duration(milliseconds: 400),
                                              child: CustomConfirmDialog(
                                                title: "Confirm Purchase",
                                                content:
                                                "You’re about to unlock lifetime access. Continue to manual payment form?",
                                                onConfirm: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => PaymentFormScreen(),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),

                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Already Paid User (Non-Trial)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Thank you for subscribing! You have full access to all features.",
                                    style: TextStyle(
                                      fontSize: getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  }

                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 30),

              // Currency Dropdown
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Currency", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Consumer<CurrencyProvider>(
                        builder: (context, provider, _) {
                          if (provider.selectedCurrency == null) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButton<Map<String, dynamic>>(
                            isExpanded: true,
                            value: provider.selectedCurrency,
                            onChanged: (value) {
                              if (value != null && value != provider.selectedCurrency) {
                                provider.selectCurrency(value);
                              }
                            },
                            items: provider.currencies.map((currency) {
                              return DropdownMenuItem(
                                value: currency,
                                child: Row(
                                  children: [
                                    Text(currency['symbol'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(currency['name'])),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),

              // Email
              _profileTile(
                context,
                icon: LucideIcons.mail,
                title: "Account Email",
                subtitle: accountEmail ?? 'Loading...',
              ),

              // About Developer
              _profileTile(
                context,
                icon: LucideIcons.info,
                title: "About the Developer",
                subtitle: aboutDev,
              ),

              const SizedBox(height: 10),

              // Logout Button
              Consumer2<AuthPaymentProvider, TabProvider>(
                builder: (context, authPaymentProvider, tabProvider, _) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: CustomButton(
                      color: AppColor.error,
                      label: "Logout",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => FadeInDown(
                            duration: const Duration(milliseconds: 400),
                            child: CustomConfirmDialog(
                              title: "Logout Confirmation",
                              content:
                              "Are you sure you want to log out? You will need to sign in again to access your account.",
                              onConfirm: () {
                                authPaymentProvider.logout();
                                tabProvider.setFirstTimeFlag(true);
                                Phoenix.rebirth(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        VoidCallback? onTap,
      }) {
    final bool isAboutDeveloper = title == "About the Developer";

    return FadeInUp(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColor.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColor.textSecondary),
                      overflow: isAboutDeveloper ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
