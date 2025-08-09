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
    _checkInternetThenInit();
  }

  Future<void> _checkInternetThenInit() async {
    final online = await InternetChecker.hasInternet();
    if (!online) {
      print("🌐❌ No internet detected — restarting in 5s...");
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) Phoenix.rebirth(context);
      });
      return;
    }

    // If online, proceed as normal
    _checkAccessFlow();
    _checkTrialExpired();
  }


  // ------------------------------------------------
  // TRIAL EXPIRATION CHECK
  // ------------------------------------------------
  Future<void> _checkTrialExpired() async {
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    final now = DateTime.now();
    final storedExpirationDate = await secureStorageService.readTrialExpirationDate();

    // 1. Local expiration check first
    if (storedExpirationDate != null) {
      print("🗄️ Local expiration: $storedExpirationDate");

      if (now.isAfter(storedExpirationDate)) {
        print("⛔ Local trial expired. Ending trial without server check.");
        tabProvider.setFirstTimeFlag(true);
        await purchaseService.toggleTrial(false);
        return;
      } else {
        print("✅ Local trial still active — will verify with Supabase if possible.");
      }
    } else {
      print("📭 No local expiration found — will try Supabase.");
    }

    // 2. Try Supabase only if online or needed
    try {
      final paymentDetails = await purchaseService.getPaymentDetails();

      if (paymentDetails == null) {
        print("⚠️ Supabase returned null. Keeping current local state.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Parse Supabase expiration
      final supabaseRaw = paymentDetails['expirationDate'];
      final supabaseExpirationDate = (supabaseRaw is String)
          ? DateTime.tryParse(supabaseRaw)
          : supabaseRaw is DateTime
          ? supabaseRaw
          : null;

      if (supabaseExpirationDate == null) {
        print("⚠️ Supabase expiration field is null. Keeping local state.");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      print("☁️ Supabase expiration: $supabaseExpirationDate");

      // Tampering detection
      if (storedExpirationDate != null &&
          storedExpirationDate.isBefore(supabaseExpirationDate)) {
        print("🚨 Possible tampering detected — resetting trial.");
        tabProvider.setFirstTimeFlag(true);
        await purchaseService.toggleTrial(false);
        return;
      }

      // Sync local if different
      if (storedExpirationDate == null ||
          storedExpirationDate != supabaseExpirationDate) {
        await secureStorageService.saveTrialExpirationDate(supabaseExpirationDate);
        print("🔁 Synced Supabase expiration to local.");
      }

      // Final expiration check from Supabase
      if (now.isAfter(supabaseExpirationDate)) {
        print("⛔ Trial expired (Supabase).");
        tabProvider.setFirstTimeFlag(true);
        await purchaseService.toggleTrial(false);
        return;
      }

      print("✅ Trial active until $supabaseExpirationDate (Supabase)");
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print("🌐❌ Failed to fetch from Supabase: $e — using local state.");
      // If we still have a valid local date, just continue
      if (storedExpirationDate != null && now.isBefore(storedExpirationDate)) {
        if (mounted) setState(() => _isLoading = false);
      } else {
        // No valid local state — safest is to end trial
        tabProvider.setFirstTimeFlag(true);
        await purchaseService.toggleTrial(false);
      }
    }
  }

  // ------------------------------------------------
  // ACCESS FLOW CHECK
  // ------------------------------------------------
  Future<void> _checkAccessFlow() async {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();

    bool isTrial = false;
    bool isPurchase = false;

    try {
      // Fetch trial & purchase once
      isTrial = await purchaseService.getTrial();
      isPurchase = await purchaseService.getPurchase();

      // Save flags if successful
      await secureStorageService.saveTrialAndPurchaseFlags(
        isTrial: isTrial,
        isPurchase: isPurchase,
      );
    } catch (e) {
      // Fallback to cached values
      print("⚠️ Could not fetch purchase/trial status, using cached values: $e");
      final cachedFlags = await secureStorageService.readTrialAndPurchaseFlags();
      isTrial = cachedFlags['is_trial'] ?? false;
      isPurchase = cachedFlags['is_purchase'] ?? false;
    }

    final isTrialOrPurchaseActive = isTrial || isPurchase;

    if (isTrialOrPurchaseActive) {
      print("[Home] ✅ Trial or purchase active — skipping auth flow.");
      setState(() => _isLoading = false);
      return;
    }else{

    }

    // First-time user → go to auth
    if (tabProvider.isFirstTime) {
      _navigateToAuth();
      return;
    }

    try {
      // Check if payment data exists
      final details = await purchaseService.getPaymentDetails();
      final hasPaymentData = details != null &&
          (details['paymentMethod'] as String?)?.isNotEmpty == true &&
          (details['paymentProofUrl'] as String?)?.isNotEmpty == true;

      if (hasPaymentData && !isPurchase) {
        print("🧾 Payment method and proof provided.");
        _navigateToVerificationPaymentScreen();
        return;
      }
    } catch (e) {
      print("⚠️ Could not fetch payment details: $e");
    }

    print("❌ Missing payment method or proof.");
    if (!isTrial && !isPurchase) {
      _navigateToVerification(purchaseService, secureStorageService);
      return;
    }

    setState(() => _isLoading = false);
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

  void _navigateToVerification(PurchaseService purchaseService, SecureStorageService secureStorageService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          onFreeTrial: () => _showFreeTrialDialog(purchaseService,secureStorageService),
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

  void _showFreeTrialDialog(
      PurchaseService purchaseService,
      SecureStorageService secureStorageService,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: CustomConfirmDialog(
          isPop: false,
          children: [const SizedBox.shrink()],
          title: "Enjoy a 7-Day Free Trial",
          content: "You’ll get full access to all features for 7 days — totally free\n\nWant to start your trial now?",
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
              // Optionally show error dialog here
            }
          },
        ),
      ),
    );
  }


  void _showPurchaseFlow(PurchaseService purchaseService) {
    // Store the outer context so we can use it even after PaymentForm is popped
    final safeContext = context;

    Navigator.push(
      safeContext,
      MaterialPageRoute(
        builder: (_) => PaymentForm(
          onSubmit: (String paymentMethod, File file) {
            Navigator.pop(safeContext); // Close PaymentForm page
            Future.microtask(() {
              _showConfirmPaymentDialog(
                purchaseService,
                paymentMethod,
                file,
                safeContext, // use safe context
              );
            });
          },
        ),
      ),
    );
  }

  void _showConfirmPaymentDialog(
      PurchaseService purchaseService,
      String paymentMethod,
      File file,
      BuildContext ctx, // safe context passed here
      ) {
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
