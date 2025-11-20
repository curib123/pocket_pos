import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:pocketpos/Helper/Classes_Methods/InternetChecker.dart';
import 'package:provider/provider.dart';

import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
import 'package:pocketpos/Helper/Database/PurchaseService.dart';
import 'package:pocketpos/Provider/TabProvider.dart';

import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Components/Widgets/BottomNavigation.dart';
import 'package:pocketpos/View/Screen/Sub/AuthScreen.dart';
import 'package:pocketpos/View/Screen/Sub/PaymentForm.dart';
import 'package:pocketpos/View/Screen/Sub/VerificationPaymentScreen.dart';
import 'package:pocketpos/View/Screen/Sub/VerificationScreen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// -------------------------------------------------------------
// 🔥 MASTER SWITCH — DISABLE ALL RESTRICTIONS
// -------------------------------------------------------------
const bool restrict = false; // set false = NO LOGIN, NO TRIAL, NO PURCHASE, NO CHECKS

class _HomeState extends State<Home> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndInit();
  }

  // MAIN ENTRY LOGIC
  Future<void> _checkAccessAndInit() async {
    // -------------------------------------------------------------
    // 🔥 If restriction is turned OFF → skip everything
    // -------------------------------------------------------------
    if (!restrict) {
      print("🚀 Restriction OFF → Skipping all checks.");
      Future.delayed(Duration.zero, () {
        setState(() => _isLoading = false);
      });
      return;
    }

    // -------------------------------------------------------------
    // ORIGINAL RESTRICTION LOGIC BELOW
    // (Only runs if restrict = true)
    // -------------------------------------------------------------

    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();

    bool isTrial = false;
    bool isPurchase = false;

    final cachedFlags = await secureStorageService.readTrialAndPurchaseFlags();
    isTrial = cachedFlags['is_trial'] ?? false;
    isPurchase = cachedFlags['is_purchase'] ?? false;

    if (isTrial || isPurchase) {
      await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: true);
      return;
    }

    try {
      final serverTrial = await purchaseService.getTrial()
          .timeout(Duration(seconds: 5));
      final serverPurchase = await purchaseService.getPurchase()
          .timeout(Duration(seconds: 5));

      isTrial = serverTrial;
      isPurchase = serverPurchase;

      await secureStorageService.saveTrialAndPurchaseFlags(
        isTrial: isTrial,
        isPurchase: isPurchase,
      );
    } catch (_) {}

    if (isTrial || isPurchase) {
      await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: true);
      return;
    }

    final online = await InternetChecker.hasInternet();
    if (!online) {
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) Phoenix.rebirth(context);
      });
      return;
    }

    await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: false);
  }

  Future<void> _runAccessFlow(
      bool isTrial, bool isPurchase,
      {bool skipSupabaseIfOffline = false}) async {

    // 🔥 SKIP if restriction OFF
    if (!restrict) {
      setState(() => _isLoading = false);
      return;
    }

    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    final now = DateTime.now();
    final storedExpirationDate = await secureStorageService.readTrialExpirationDate();

    // Trial processing logic...
    if (isTrial) {
      bool needSupabaseCheck = false;

      if (storedExpirationDate != null) {
        if (now.isAfter(storedExpirationDate)) {
          isTrial = false;
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
        } else {
          if (!skipSupabaseIfOffline) needSupabaseCheck = true;
        }
      } else {
        needSupabaseCheck = !skipSupabaseIfOffline;
      }

      if (isTrial && needSupabaseCheck) {
        try {
          final paymentDetails = await purchaseService.getPaymentDetails();
          final supabaseExpiration = DateTime.tryParse(
              paymentDetails?['expirationDate'] ?? "");

          if (supabaseExpiration != null &&
              now.isAfter(supabaseExpiration)) {
            isTrial = false;
            tabProvider.setFirstTimeFlag(true);
            await purchaseService.toggleTrial(false);
          }
        } catch (_) {}
      }
    }

    if (isTrial || isPurchase) {
      setState(() => _isLoading = false);
      return;
    }

    if (tabProvider.isFirstTime) {
      _navigateToAuth();
      return;
    }

    try {
      final details = await purchaseService.getPaymentDetails();
      final hasData =
          details != null &&
              (details['paymentMethod'] as String?)?.isNotEmpty == true &&
              (details['paymentProofUrl'] as String?)?.isNotEmpty == true;

      if (hasData && !isPurchase) {
        _navigateToVerificationPaymentScreen();
        return;
      }
    } catch (_) {}

    _navigateToVerification(purchaseService, secureStorageService);
  }

  // -------------------------------------------------------------
  // NAVIGATION FUNCTIONS
  // -------------------------------------------------------------
  void _navigateToVerificationPaymentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerificationPaymentScreen(
        onApproved: () {
          Phoenix.rebirth(context);
        },
      )),
    );
  }

  void _navigateToVerification(PurchaseService purchaseService,
      SecureStorageService secureStorageService) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerificationScreen(
        onFreeTrial: () => {},
        onPurchase: () => {},
      )),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<TabProvider>(
      builder: (context, tabProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: tabProvider.screens[tabProvider.currentIndex],
          bottomNavigationBar: BottomNavigation(
            currentIndex: tabProvider.currentIndex,
            onTabSelected: tabProvider.setTab,
          ),
        );
      },
    );
  }
}
