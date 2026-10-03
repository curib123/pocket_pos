import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';

class StartIoBannerSlot extends StatefulWidget {
  final bool visible;

  const StartIoBannerSlot({
    super.key,
    required this.visible,
  });

  @override
  State<StartIoBannerSlot> createState() => _StartIoBannerSlotState();
}

class _StartIoBannerSlotState extends State<StartIoBannerSlot> {
  final StartAppSdk _sdk = StartAppSdk();
  StartAppBannerAd? _bannerAd;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading || _bannerAd != null) return;
    _loading = true;
    try {
      final ad = await _sdk.loadBannerAd(
        StartAppBannerType.BANNER,
        prefs: const StartAppAdPreferences(adTag: 'main_banner'),
      );
      if (!mounted) return;
      setState(() => _bannerAd = ad);
    } catch (error) {
      debugPrint('Start.io banner failed to load: $error');
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!widget.visible || ad == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Center(child: StartAppBanner(ad)),
      ),
    );
  }
}
