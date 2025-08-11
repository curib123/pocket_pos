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

class _HomeState extends State<Home> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndInit();
  }

  /// 🔍 Checks trial/purchase first, then internet if needed
  Future<void> _checkAccessAndInit() async {
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();

    bool isTrial = false;
    bool isPurchase = false;

    // 1️⃣ Try from local cache first
    final cachedFlags = await secureStorageService.readTrialAndPurchaseFlags();
    isTrial = cachedFlags['is_trial'] ?? false;
    isPurchase = cachedFlags['is_purchase'] ?? false;

    // 🚀 NEW: If trial/purchase active in cache → skip server calls entirely
    if (isTrial || isPurchase) {
      print("✅ Using cached trial/purchase — skipping server check.");
      await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: true);
      return;
    }

    // 2️⃣ No active trial/purchase in cache → try refreshing from server
    try {
      final serverTrial = await purchaseService.getTrial()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException("getTrial() took too long");
      });

      final serverPurchase = await purchaseService.getPurchase()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException("getPurchase() took too long");
      });

      isTrial = serverTrial;
      isPurchase = serverPurchase;

      await secureStorageService.saveTrialAndPurchaseFlags(
        isTrial: isTrial,
        isPurchase: isPurchase,
      );
    } catch (e) {
      print("⚠️ Could not refresh trial/purchase from server: $e");
    }

    // 3️⃣ If trial/purchase active after server refresh → skip internet check
    if (isTrial || isPurchase) {
      print("✅ Trial/Purchase active — skipping internet check.");
      await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: true);
      return;
    }

    // 4️⃣ No trial/purchase → must be online
    final online = await InternetChecker.hasInternet();
    if (!online) {
      print("🌐❌ No internet detected — restarting in 5s...");
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) Phoenix.rebirth(context);
      });
      return;
    }

    await _runAccessFlow(isTrial, isPurchase, skipSupabaseIfOffline: false);
  }

  /// 🚦 Combined logic for access + trial expiration check
  Future<void> _runAccessFlow(
      bool isTrial, bool isPurchase, {bool skipSupabaseIfOffline = false}) async {
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    final now = DateTime.now();
    final storedExpirationDate =
    await secureStorageService.readTrialExpirationDate();

    // Trial expiration check
    if (isTrial) {
      bool needSupabaseCheck = false;

      if (storedExpirationDate != null) {
        if (now.isAfter(storedExpirationDate)) {
          // Expired locally
          print("⛔ Trial expired (Local).");
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
          isTrial = false;
        } else {
          print("✅ Trial active locally until $storedExpirationDate.");
          // Only hit Supabase if we're online and not skipping
          if (!skipSupabaseIfOffline) needSupabaseCheck = true;
        }
      } else {
        // No local expiration → must verify online if possible
        needSupabaseCheck = true;
      }

      if (isTrial && needSupabaseCheck) {
        try {
          final paymentDetails = await purchaseService.getPaymentDetails();
          final supabaseRaw = paymentDetails?['expirationDate'];
          final supabaseExpirationDate = (supabaseRaw is String)
              ? DateTime.tryParse(supabaseRaw)
              : supabaseRaw is DateTime
              ? supabaseRaw
              : null;

          if (supabaseExpirationDate != null &&
              now.isAfter(supabaseExpirationDate)) {
            print("⛔ Trial expired (Supabase).");
            tabProvider.setFirstTimeFlag(true);
            await purchaseService.toggleTrial(false);
            isTrial = false;
          } else if (supabaseExpirationDate != null &&
              storedExpirationDate != supabaseExpirationDate) {
            await secureStorageService
                .saveTrialExpirationDate(supabaseExpirationDate);
          }
        } catch (e) {
          print("🌐❌ Failed to verify trial online: $e — keeping local state.");
        }
      }
    }

    // ✅ If still trial or purchased → go straight to home
    if (isTrial || isPurchase) {
      setState(() => _isLoading = false);
      return;
    }

    // First-time user → Auth screen
    if (tabProvider.isFirstTime) {
      _navigateToAuth();
      return;
    }

    // Payment details check
    try {
      final details = await purchaseService.getPaymentDetails();
      final hasPaymentData = details != null &&
          (details['paymentMethod'] as String?)?.isNotEmpty == true &&
          (details['paymentProofUrl'] as String?)?.isNotEmpty == true;

      if (hasPaymentData && !isPurchase) {
        _navigateToVerificationPaymentScreen();
        return;
      }
    } catch (e) {
      print("⚠️ Could not fetch payment details: $e");
    }

    // Missing payment data → Verification screen
    _navigateToVerification(purchaseService, secureStorageService);
  }

  // ------------------------------------------------
  // NAVIGATION HELPERS
  // ------------------------------------------------
  void _navigateToVerificationPaymentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (newContext) => VerificationPaymentScreen(
          onApproved: () async {
            await Future.delayed(const Duration(milliseconds: 300));
            Phoenix.rebirth(newContext);
          },
        ),
      ),
    );
  }

  void _navigateToVerification(PurchaseService purchaseService,
      SecureStorageService secureStorageService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          onFreeTrial: () =>
              _showFreeTrialDialog(purchaseService, secureStorageService),
          onPurchase: () => _showPurchaseFlow(purchaseService),
        ),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _showFreeTrialDialog(PurchaseService purchaseService,
      SecureStorageService secureStorageService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: CustomConfirmDialog(
          isPop: false,
          children: [const SizedBox.shrink()],
          title: "Enjoy a 7-Day Free Trial",
          content:
          "You’ll get full access to all features for 7 days — totally free\n\nWant to start your trial now?",
          onConfirm: () async {
            const isTrial = true;
            const isPurchase = false;

            try {
              await purchaseService.upsertPurchaseDefaults(
                isTrial: isTrial,
                isPurchase: isPurchase,
                trialExpiration: DateTime.now().add(const Duration(days: 7)),
              );

              await secureStorageService.saveTrialAndPurchaseFlags(
                isTrial: isTrial,
                isPurchase: isPurchase,
              );

              Phoenix.rebirth(context);
            } catch (e, st) {
              debugPrint("❌ Failed to start trial: $e");
              debugPrintStack(stackTrace: st);
            }
          },
        ),
      ),
    );
  }

  void _showPurchaseFlow(PurchaseService purchaseService) {
    final safeContext = context;

    Navigator.push(
      safeContext,
      MaterialPageRoute(
        builder: (_) => PaymentForm(
          onSubmit: (String paymentMethod, File file) {
            Navigator.pop(safeContext);
            Future.microtask(() {
              _showConfirmPaymentDialog(
                purchaseService,
                paymentMethod,
                file,
                safeContext,
              );
            });
          },
        ),
      ),
    );
  }

  void _showConfirmPaymentDialog(PurchaseService purchaseService,
      String paymentMethod, File file, BuildContext ctx) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: CustomConfirmDialog(
          title: "Confirm Payment Submission",
          content:
          "Are you sure you want to submit this payment using \"$paymentMethod\"?",
          onConfirm: () async {
            Navigator.of(ctx).pop();
            try {
              await purchaseService.sendPayment(
                file: file,
                paymentMethod: paymentMethod,
              );
              Phoenix.rebirth(ctx);
            } catch (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('❌ Failed to submit payment: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
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
