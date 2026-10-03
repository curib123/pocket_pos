import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:nextpos/Provider/AuthProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:nextpos/View/Screen/Sub/RestoreProductScreen.dart';
import 'package:nextpos/View/Screen/Sub/SetupCategoryScreen.dart';
import 'package:nextpos/View/Screen/Sub/StockLogsHistoryScreen.dart';
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
          final user = userSnapshot.data ?? const <String, String?>{};

          return Consumer3<AuthProvider, TabProvider, ProductProvider>(
            builder: (context, authProvider, tabProvider, productProvider, _) {
              return SafeArea(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final appName = snapshot.data?.appName ?? 'Pocket Inventory';
                    final version = snapshot.data?.version ?? '1.0.0';
                    final buildNumber = snapshot.data?.buildNumber ?? '1';
                    final storeName = user['storeName'] ?? 'Your Sari-sari Store';
                    final ownerName = user['ownerName'] ?? 'Owner';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(storeName, ownerName),
                          const SizedBox(height: 18),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionTitle(title: 'Inventory'),
                                  _DrawerItem(
                                    icon: LucideIcons.layoutDashboard,
                                    label: 'Dashboard',
                                    onTap: () => _selectTab(context, tabProvider, 0),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.boxes,
                                    label: 'Products',
                                    onTap: () => _selectTab(context, tabProvider, 1),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.arrowLeftRight,
                                    label: 'Stock In / Out / Adjustment',
                                    onTap: () => _selectTab(context, tabProvider, 2),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.history,
                                    label: 'Stock Movement History',
                                    onTap: () => _push(
                                      context,
                                      const StockLogsHistoryScreen(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const _SectionTitle(title: 'Manage'),
                                  _DrawerItem(
                                    icon: LucideIcons.tags,
                                    label: 'Categories',
                                    onTap: () => _push(
                                      context,
                                      const SetupCategoryScreen(),
                                    ),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.rotateCcw,
                                    label: 'Restore Deleted Products',
                                    onTap: () => _push(
                                      context,
                                      const RestoreProductScreen(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          _DrawerItem(
                            icon: LucideIcons.info,
                            label: 'About',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: appName,
                                applicationVersion: 'v' + version + ' (' + buildNumber + ')',
                                applicationLegalese:
                                    '© ' + DateTime.now().year.toString() + ' CuribTech',
                                children: const [
                                  SizedBox(height: 16),
                                  Text(
                                    'Pocket Inventory is an offline-first sari-sari store inventory tracker focused on products, Stock In, Stock Out, adjustments, and movement history.',
                                    style: TextStyle(height: 1.5),
                                  ),
                                ],
                              );
                            },
                          ),
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
                                  content:
                                      'Signing out will clear local account data. Continue?',
                                  onConfirm: () async {
                                    await authProvider.signOut(
                                      tabProvider,
                                      productProvider,
                                      context,
                                    );
                                    if (context.mounted) Phoenix.rebirth(context);
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
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

  void _selectTab(BuildContext context, TabProvider provider, int index) {
    Navigator.pop(context);
    provider.setTab(index);
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildHeader(String storeName, String ownerName) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 26,
          backgroundColor: AppColor.primary,
          child: Icon(LucideIcons.store, color: Colors.white, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColor.textSecondary),
              ),
              const SizedBox(height: 2),
              const Text(
                'Sari-sari Inventory',
                style: TextStyle(fontSize: 12, color: AppColor.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColor.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
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
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, size: 20, color: AppColor.primary),
      title: Text(label),
      onTap: onTap,
    );
  }
}
