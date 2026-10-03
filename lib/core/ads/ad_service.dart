import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startapp_sdk/startapp.dart';

/// Centralized Start.io policy for Pocket Inventory.
///
/// The policy intentionally favors steady banner revenue and infrequent
/// interstitials at natural breaks. Splash and return ads are disabled in the
/// Android manifest so users are never interrupted just for opening the app.
class StartIoAdService {
  StartIoAdService._();

  static final StartIoAdService instance = StartIoAdService._();

  static const int _naturalBreaksBeforeInterstitial = 6;
  static const int _maxInterstitialsPerDay = 4;
  static const Duration _firstInterstitialDelay = Duration(minutes: 2);
  static const Duration _interstitialCooldown = Duration(minutes: 4);

  static const String _prefDay = 'startio_interstitial_day';
  static const String _prefCount = 'startio_interstitial_count';
  static const String _prefLastShown = 'startio_interstitial_last_shown_ms';

  final StartAppSdk _sdk = StartAppSdk();
  final DateTime _sessionStartedAt = DateTime.now();

  StartAppInterstitialAd? _interstitial;
  bool _loadingInterstitial = false;
  bool _initialized = false;
  int _naturalBreaks = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _sdk.setTestAdsEnabled(kDebugMode);
    } catch (error) {
      debugPrint('Start.io test-mode setup failed: $error');
    }

    unawaited(_preloadInterstitial());
  }

  /// Call only after a user reaches a natural break, such as completing a
  /// stock update or intentionally changing main sections.
  Future<void> registerNaturalBreak() async {
    if (!_initialized) {
      await initialize();
    }

    _naturalBreaks += 1;
    if (_naturalBreaks < _naturalBreaksBeforeInterstitial) return;

    final now = DateTime.now();
    if (now.difference(_sessionStartedAt) < _firstInterstitialDelay) return;
    if (!await _canShowInterstitial(now)) return;

    final ad = _interstitial;
    if (ad == null) {
      unawaited(_preloadInterstitial());
      return;
    }

    _naturalBreaks = 0;
    _interstitial = null;

    try {
      final shown = await ad.show();
      if (shown) {
        await _recordInterstitialShown(now);
      } else {
        unawaited(_preloadInterstitial());
      }
    } catch (error) {
      debugPrint('Start.io interstitial failed to show: $error');
      try {
        ad.dispose();
      } catch (_) {}
      unawaited(_preloadInterstitial());
    }
  }

  Future<void> _preloadInterstitial() async {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;

    try {
      late StartAppInterstitialAd loadedAd;
      var released = false;

      void release() {
        if (released) return;
        released = true;
        if (identical(_interstitial, loadedAd)) {
          _interstitial = null;
        }
        try {
          loadedAd.dispose();
        } catch (_) {}
        unawaited(_preloadInterstitial());
      }

      loadedAd = await _sdk.loadInterstitialAd(
        prefs: const StartAppAdPreferences(
          adTag: 'inventory_natural_break',
        ),
        onAdHidden: release,
        onAdNotDisplayed: release,
      );
      _interstitial = loadedAd;
    } catch (error) {
      debugPrint('Start.io interstitial preload failed: $error');
    } finally {
      _loadingInterstitial = false;
    }
  }

  Future<bool> _canShowInterstitial(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final day = _dayKey(now);
    final storedDay = prefs.getString(_prefDay);

    if (storedDay != day) {
      await prefs.setString(_prefDay, day);
      await prefs.setInt(_prefCount, 0);
    }

    final count = prefs.getInt(_prefCount) ?? 0;
    if (count >= _maxInterstitialsPerDay) return false;

    final lastShownMs = prefs.getInt(_prefLastShown);
    if (lastShownMs != null) {
      final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);
      if (now.difference(lastShown) < _interstitialCooldown) return false;
    }

    return true;
  }

  Future<void> _recordInterstitialShown(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final day = _dayKey(now);
    if (prefs.getString(_prefDay) != day) {
      await prefs.setString(_prefDay, day);
      await prefs.setInt(_prefCount, 0);
    }
    final count = prefs.getInt(_prefCount) ?? 0;
    await prefs.setInt(_prefCount, count + 1);
    await prefs.setInt(_prefLastShown, now.millisecondsSinceEpoch);
  }

  String _dayKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';
}
