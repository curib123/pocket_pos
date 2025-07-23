import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocketpos/Helper/Classes_Methods/AppColor.dart';
import 'package:pocketpos/Provider/AuthProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColor.background,
      child: Consumer3<AuthProvider,TabProvider,ProductProvider>(
        builder: (context,authProvider,tabProvider,productProvider,_) {
          return SafeArea(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final appName = snapshot.data?.appName ?? '...';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeader(appName),
                      const SizedBox(height: 16),


                      const Spacer(),

                      const Divider(thickness: 1, color: AppColor.textSecondary),
                      const SizedBox(height: 8),

                      _buildDrawerItem(
                        icon: LucideIcons.settings,
                        text: 'Settings',
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      const SizedBox(height: 8),

                      _buildDrawerItem(
                        icon: LucideIcons.logOut,
                        text: 'Logout',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => CustomConfirmDialog(
                              icon: Icons.logout_rounded,
                              isPop: false,
                              title: 'Sign Out',
                              content: 'Are you sure you want to sign out? Your local data will be cleared.',
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
                );
              },
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(String appName) {
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mobile POS and Inventory App',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppColor.textSecondary,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          ],
        ),
      ],
    );
  }


  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColor.textSecondary),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
