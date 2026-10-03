import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/Provider/OfflineDataProvider.dart';
import 'package:nextpos/View/Components/Brand/BantayStockBrand.dart';
import 'package:nextpos/View/Screen/Sub/RestoreProductScreen.dart';
import 'package:nextpos/View/Screen/Sub/SetupCategoryScreen.dart';
import 'package:nextpos/core/brand/app_brand.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _accountEmail = '';
  String _storeName = 'My Store';
  String _ownerName = 'Store owner';

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CurrencyProvider>().loadCurrency();
  }

  Future<void> _loadUserDetails() async {
    final details = await SecureStorageService().readUser();
    if (!mounted) return;
    setState(() {
      _accountEmail = details['email'] ?? '';
      _storeName = _clean(details['storeName'], 'My Store');
      _ownerName = _clean(details['ownerName'], 'Store owner');
    });
  }

  String _clean(String? value, String fallback) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty || clean.toLowerCase() == 'unknown') return fallback;
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppBrand.surface,
              border: Border.all(color: AppBrand.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const BantayStockMark(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _ownerName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppBrand.muted,
                            ),
                      ),
                      if (_accountEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _accountEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppBrand.muted,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              Consumer<CurrencyProvider>(
                builder: (context, provider, _) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: DropdownButtonFormField<Map<String, dynamic>>(
                      value: provider.selectedCurrency,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items: provider.currencies
                          .map(
                            (currency) =>
                                DropdownMenuItem<Map<String, dynamic>>(
                              value: currency,
                              child: Text(
                                '${currency['symbol']}  ${currency['name']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null &&
                            value != provider.selectedCurrency) {
                          provider.selectCurrency(value);
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Inventory'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Organize products into simple groups',
                onTap: () => _push(const SetupCategoryScreen()),
              ),
              const Divider(indent: 58),
              _SettingsTile(
                icon: Icons.restore_from_trash_outlined,
                title: 'Deleted products',
                subtitle: 'Review and restore archived products',
                onTap: () => _push(const RestoreProductScreen()),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Data'),
          const SizedBox(height: 8),
          Consumer<OfflineDataProvider>(
            builder: (context, offline, _) => _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Backup data',
                  subtitle: offline.isBusy
                      ? 'Preparing your backup…'
                      : 'Save a copy of products, stock, and activity',
                  onTap: offline.isBusy ? null : _backup,
                ),
                const Divider(indent: 58),
                _SettingsTile(
                  icon: Icons.upload_outlined,
                  title: 'Restore backup',
                  subtitle: offline.isBusy
                      ? 'Restoring data…'
                      : 'Restore from a BantayStock backup file',
                  onTap: offline.isBusy ? null : _restore,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SectionLabel('About'),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data == null
                  ? 'Version'
                  : 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})';
              return _SettingsCard(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: BantayStockBrand(
                      showTagline: true,
                      markSize: 42,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: Text(
                      '$version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppBrand.muted,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _backup() async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save BantayStock backup',
      fileName:
          'bantaystock-backup-${DateTime.now().toIso8601String().split('T').first}.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (!mounted || path == null) return;

    try {
      await context.read<OfflineDataProvider>().backupTo(File(path));
      if (!mounted) return;
      _message('Backup saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _message('Backup failed: $error');
    }
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (!mounted || path == null) return;

    try {
      final count = await context
          .read<OfflineDataProvider>()
          .restoreFrom(File(path));
      if (!mounted) return;
      _message('Restored $count product records.');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) Phoenix.rebirth(context);
    } catch (error) {
      if (!mounted) return;
      _message('Restore failed: $error');
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppBrand.muted,
          ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppBrand.surface,
        border: Border.all(color: AppBrand.border),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 34,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppBrand.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppBrand.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: onTap == null
          ? const SizedBox.shrink()
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
