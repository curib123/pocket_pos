import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nextpos/Helper/Classes_Methods/AppColor.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:nextpos/Provider/AuthProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:nextpos/View/Components/Brand/PocketInventoryBrand.dart';
import 'package:nextpos/View/Components/Inventory/StockMovementSheet.dart';
import 'package:nextpos/View/Screen/Sub/RestoreProductScreen.dart';
import 'package:nextpos/View/Screen/Sub/SetupCategoryScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final secureStorage = SecureStorageService();

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(context, storeName, ownerName),
                          const SizedBox(height: 18),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionTitle(title: 'Navigate'),
                                  _DrawerItem(
                                    icon: LucideIcons.layoutDashboard,
                                    label: 'Home',
                                    selected: tabProvider.currentIndex == 0,
                                    onTap: () =>
                                        _selectTab(context, tabProvider, 0),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.boxes,
                                    label: 'Inventory',
                                    selected: tabProvider.currentIndex == 1,
                                    onTap: () =>
                                        _selectTab(context, tabProvider, 1),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.history,
                                    label: 'Activity',
                                    selected: tabProvider.currentIndex == 2,
                                    onTap: () =>
                                        _selectTab(context, tabProvider, 2),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.settings,
                                    label: 'Settings',
                                    selected: tabProvider.currentIndex == 3,
                                    onTap: () =>
                                        _selectTab(context, tabProvider, 3),
                                  ),
                                  const SizedBox(height: 14),
                                  const _SectionTitle(title: 'Quick stock'),
                                  _DrawerItem(
                                    icon: LucideIcons.plus,
                                    label: 'Stock In',
                                    onTap: () => _openMovement(
                                      context,
                                      StockMovementType.stockIn,
                                    ),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.minus,
                                    label: 'Stock Out',
                                    onTap: () => _openMovement(
                                      context,
                                      StockMovementType.stockOut,
                                    ),
                                  ),
                                  _DrawerItem(
                                    icon: LucideIcons.slidersHorizontal,
                                    label: 'Adjust stock',
                                    onTap: () => _openMovement(
                                      context,
                                      StockMovementType.adjustment,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
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
                                    label: 'Deleted products',
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
                                applicationVersion:
                                    'v$version ($buildNumber)',
                                applicationIcon:
                                    const PocketInventoryMark(size: 48),
                                applicationLegalese:
                                    '© ${DateTime.now().year} Pocket Inventory',
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
                                    if (context.mounted) {
                                      Phoenix.rebirth(context);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
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
    provider.setTab(index);
    Navigator.pop(context);
  }

  void _openMovement(BuildContext context, StockMovementType type) {
    final navigator = Navigator.of(context);
    final hostContext = navigator.context;
    navigator.pop();
    Future<void>.delayed(Duration.zero, () {
      StockMovementSheet.show(hostContext, type: type);
    });
  }

  void _push(BuildContext context, Widget screen) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildHeader(
    BuildContext context,
    String storeName,
    String ownerName,
  ) {
    return Row(
      children: [
        const PocketInventoryMark(size: 54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pocket Inventory',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: AppColor.primary.withOpacity(.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        size: 20,
        color: selected ? AppColor.primary : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
