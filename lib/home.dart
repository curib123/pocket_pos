import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
import 'package:pocketpos/View/Components/Alert/CustomConfimDialog.dart';
import 'package:pocketpos/View/Screen/Sub/VerificationScreen.dart';
import 'package:provider/provider.dart';

import 'package:pocketpos/Helper/Database/PurchaseService.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/View/Components/Widgets/BottomNavigation.dart';
import 'package:pocketpos/View/Screen/Sub/AuthScreen.dart';

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
    _checkAccessFlow();
    _checkTrialExpired(); // will retry automatically if offline
  }

  Future<void> _checkTrialExpired() async {
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    DateTime now = DateTime.now();

    // 1. Check local expiration first
    DateTime? storedExpirationDate = await secureStorageService.readTrialExpirationDate();
    if (storedExpirationDate != null) {
      print("🗄️ Local expiration: $storedExpirationDate");

      if (now.isAfter(storedExpirationDate)) {
        print("⛔ Local trial expired.");
      } else {
        print("✅ Local trial still active.");
      }
    } else {
      print("📭 No local expiration found.");
    }

    // 2. Try fetching Supabase
    try {
      final paymentDetails = await purchaseService.getPaymentDetails();

      // 🚨 If nothing is returned, restart app after delay
      if (paymentDetails == null) {
        print("⚠️ Supabase returned null. Restarting app in 5 seconds...");
        await Future.delayed(Duration(seconds: 5));
        Phoenix.rebirth(context);
        return;
      }

      final supabaseRaw = paymentDetails['expirationDate'];
      DateTime? supabaseExpirationDate;

      if (supabaseRaw is String) {
        supabaseExpirationDate = DateTime.tryParse(supabaseRaw);
      } else if (supabaseRaw is DateTime) {
        supabaseExpirationDate = supabaseRaw;
      }

      if (supabaseExpirationDate != null) {
        print("☁️ Supabase expiration: $supabaseExpirationDate");

        // Tampering check
        if (storedExpirationDate != null &&
            storedExpirationDate.isBefore(supabaseExpirationDate)) {
          print("🚨 Tampering suspected. Restarting in 5 seconds...");
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
          await Future.delayed(Duration(seconds: 5));
          Phoenix.rebirth(context);
          return;
        }

        // Sync Supabase to local
        if (storedExpirationDate == null ||
            storedExpirationDate != supabaseExpirationDate) {
          await secureStorageService.saveTrialExpirationDate(supabaseExpirationDate);
          print("🔁 Synced Supabase expiration to local.");
        }

        // Expired check
        if (now.isAfter(supabaseExpirationDate)) {
          print("⛔ Trial expired (Supabase). Restarting in 5 seconds...");
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
          await Future.delayed(Duration(seconds: 5));
          Phoenix.rebirth(context);
          return;
        } else {
          print("✅ Trial is active until $supabaseExpirationDate (Supabase)");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        print("⚠️ Supabase expiration field is null. Restarting in 5 seconds...");
        await Future.delayed(Duration(seconds: 5));
        Phoenix.rebirth(context);
        return;
      }
    } catch (e) {
      print("🌐❌ Failed to fetch from Supabase: $e. Restarting in 5 seconds...");
      await Future.delayed(Duration(seconds: 5));
      Phoenix.rebirth(context); // 💥 When in doubt, restart
    }
  }

  Future<void> _checkAccessFlow() async {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    final purchaseService = PurchaseService();

    await tabProvider.loadFirstTimeStatus();

    if (tabProvider.isFirstTime) {
      _navigateToAuth();
      return;
    }

    final hasTrial = await purchaseService.getTrial();
    final hasPurchase = await purchaseService.getPurchase();

    print('[Home] hasTrial: $hasTrial | hasPurchase: $hasPurchase');

    if (!hasTrial && !hasPurchase) {
      _navigateToVerification(purchaseService);
      return;
    }

    setState(() => _isLoading = false);
  }

  void _navigateToVerification(PurchaseService purchaseService) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          onFreeTrial: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => WillPopScope(
                onWillPop: () async => false,
                child: CustomConfirmDialog(
                  isPop: false,
                  children: [SizedBox.shrink()],
                  title: "Enjoy a 7-Day Free Trial",
                  content:
                  "You’ll get full access to all features for 7 days — totally free\n\nWant to start your trial now?",
                  onConfirm: () async {
                    await purchaseService.upsertPurchaseDefaults(
                      isTrial: true,
                      isPurchase: false,
                      trialExpiration: DateTime.now().add(const Duration(days: 7)),
                    );
                    Phoenix.rebirth(context);
                  },
                ),
              ),
            );
          },
          onPurchase: () {
            // TODO: handle purchase logic here
          },
        ),
      ),
    );
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<TabProvider>(
      builder: (context, tabProvider, child) {
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
