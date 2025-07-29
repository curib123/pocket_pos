import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
import 'package:pocketpos/Provider/AuthProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Screen/PoSReportScreen.dart';
import 'package:pocketpos/View/Screen/PosChatScreen.dart';
import 'package:pocketpos/View/Screen/ReceiptScreen.dart';
import 'package:pocketpos/View/Screen/RestoreProductScreen.dart';
import 'package:pocketpos/View/Screen/SetupCategoryScreen.dart';
import 'package:pocketpos/View/Screen/StockLogsHistoryScreen.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorageService();

    return Drawer(
      backgroundColor: AppColor.surface,
      child: FutureBuilder<Map<String, String?>>(
        future: secureStorage.readUser(),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data ?? {};

          return Consumer3<AuthProvider, TabProvider, ProductProvider>(
            builder: (context, authProvider, tabProvider, productProvider, _) {
              return SafeArea(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final appName = snapshot.data?.appName ?? 'PocketPOS';
                    final version = snapshot.data?.version ?? '1.0.0';
                    final buildNumber = snapshot.data?.buildNumber ?? '1';

                    final storeName = user['storeName'] ?? 'Your Store';
                    final ownerName = user['ownerName'] ?? 'Owner';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // 🧢 Header always on top
                          const SizedBox(height: 20),
                          _buildHeader(storeName, ownerName),
                          const SizedBox(height: 16),

                          // 📜 Scrollable middle section
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(title: 'Inventory & Sales'),
                                  _DrawerItem(
                                    icon: LucideIcons.history,
                                    label: 'Stock Activity History',
                                    onTap: () => _push(context, const StockLogsHistoryScreen()),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.receipt,
                                    label: 'Sales Receipts',
                                    onTap: () => _push(context, const ReceiptScreen()),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.rotateCcw,
                                    label: 'Restore Deleted Products',
                                    onTap: () => _push(context, const RestoreProductScreen()),
                                  ),
                                  const SizedBox(height: 16),

                                  _SectionTitle(title: 'POS AI Features'),
                                  _DrawerItem(
                                    icon: LucideIcons.bot,
                                    label: 'POS AI Chat',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => POSChatScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.barChart3,
                                    label: 'AI Report Summary',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => POSReportScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _SectionTitle(title: 'Customization'),
                                  _DrawerItem(
                                    icon: LucideIcons.tags,
                                    label: 'Manage Categories',
                                    onTap: () => _push(context, const SetupCategoryScreen()),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.info,
                                    label: 'About PocketPOS',
                                    onTap: () {
                                      showAboutDialog(
                                        context: context,
                                        applicationName: appName,
                                        applicationVersion: 'v$version ($buildNumber)',
                                        applicationLegalese: '© ${DateTime.now().year} NextTech\nAll rights reserved.',
                                        children: const [
                                          SizedBox(height: 16),
                                          Text(
                                            "PocketPOS helps you manage inventory and sales, even offline. Made for small teams doing big things.",
                                            style: TextStyle(height: 1.5),
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),

                          // 🧱 Footer always on bottom
                          Column(
                            children: [
                              const Divider(thickness: 1, color: AppColor.textSecondary),
                              const SizedBox(height: 12),
                              _DrawerItem(
                                icon: LucideIcons.settings,
                                label: 'App Settings',
                                onTap: () {
                                  showAboutDialog(context: context);
                                },
                              ),
                              const SizedBox(height: 8),
                              _DrawerItem(
                                icon: LucideIcons.logOut,
                                label: 'Sign Out',
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomConfirmDialog(
                                      icon: Icons.logout_rounded,
                                      isPop: false,
                                      title: 'Sign Out',
                                      content: 'Heads up! Signing out will clear your local data. Continue?',
                                      onConfirm: () async {
                                        await authProvider.signOut(tabProvider, productProvider, context);
                                        Phoenix.rebirth(context);
                                      },
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(String storeName, String ownerName) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppColor.primary,
          child: Icon(
            LucideIcons.store,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ownerName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColor.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mobile POS & Inventory',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColor.textSecondary),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          color: AppColor.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
