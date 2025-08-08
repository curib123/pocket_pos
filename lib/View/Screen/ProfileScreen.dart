import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/View/Components/Widgets/ResponsiveText.dart';
import 'package:provider/provider.dart';

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
    SecureStorageService secureStorage = SecureStorageService();

    final userDetails = await secureStorage.readUser(); // 👈 don't forget the await!

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
                                fontSize: getResponsiveText(context, 20),
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
                        builder: (context, provider, child) {
                          return DropdownButton<Map<String, dynamic>>(
                            isExpanded: true,
                            value: provider.selectedCurrency,
                            onChanged: (value) {
                              if (value != null && value != provider.selectedCurrency) {
                                provider.selectCurrency(value);
                              }
                            },
                            items: provider.currencies.map((currency) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: currency,
                                child: Row(
                                  children: [
                                    Text(
                                      currency['symbol'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(currency['name']),
                                    ),
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
