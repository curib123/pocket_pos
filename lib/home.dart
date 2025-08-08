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
    _checkTrialExpired();
  }


  Future<void> _checkTrialExpired() async {
    final purchaseService = PurchaseService();
    final secureStorageService = SecureStorageService();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);

    DateTime now = DateTime.now();

    // 🔐 1. Try reading from local storage
    DateTime? storedExpirationDate = await secureStorageService.readTrialExpirationDate();
    if (storedExpirationDate != null) {
      print("🗄️ Local expiration: $storedExpirationDate");

      if (now.isAfter(storedExpirationDate)) {
        print("⛔ Local trial expired.");
        // TODO: Handle local-only expiration (no internet)
        // e.g. Show expired trial dialog, restrict features, etc.
      } else {
        print("✅ Local trial still active.");
      }
    } else {
      print("📭 No local expiration found.");
      // TODO: Optional - treat no local expiration as expired, or prompt retry
    }

    // 🌐 2. Try fetching from Supabase
    try {
      final paymentDetails = await purchaseService.getPaymentDetails();

      final supabaseRaw = paymentDetails?['expirationDate'];
      DateTime? supabaseExpirationDate;

      if (supabaseRaw is String) {
        supabaseExpirationDate = DateTime.tryParse(supabaseRaw);
      } else if (supabaseRaw is DateTime) {
        supabaseExpirationDate = supabaseRaw;
      }

      if (supabaseExpirationDate != null) {
        print("☁️ Supabase expiration: $supabaseExpirationDate");

        // 🛡️ 3. Tampering check
        if (storedExpirationDate != null &&
            storedExpirationDate.isBefore(supabaseExpirationDate)) {
          print("🚨 Potential tampering: Local expiration earlier than online.");

          // TODO: Trigger tampering warning UI or notify admin
          // TODO: Show alert/toast and redirect to login or splash
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
          Phoenix.rebirth(context);
          return;
        }

        // 🔁 4. Sync to local if needed
        if (storedExpirationDate == null ||
            storedExpirationDate != supabaseExpirationDate) {
          await secureStorageService.saveTrialExpirationDate(supabaseExpirationDate);
          print("🔁 Synced Supabase expiration to local.");
        }

        // 🕒 5. Final trial expiration check
        if (now.isAfter(supabaseExpirationDate)) {
          print("⛔ Trial expired (Supabase) on $supabaseExpirationDate");

          // TODO: Lock app, show trial expired screen, or redirect to upgrade page
          tabProvider.setFirstTimeFlag(true);
          await purchaseService.toggleTrial(false);
          Phoenix.rebirth(context);
          return;
        } else {
          print("✅ Trial is active until $supabaseExpirationDate (Supabase)");
          // TODO: Continue normal flow
        }
      } else {
        print("⚠️ Supabase didn't return a valid expiration date.");
        // TODO: Show fallback UI or allow limited access
      }
    } catch (e) {
      print("🌐❌ Failed to fetch from Supabase: $e");
      // TODO: Optional - retry logic, show error message, or proceed with offline mode
    }
  }


  Future<void> _checkAccessFlow() async {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    final PurchaseService purchaseService = PurchaseService();

    await tabProvider.loadFirstTimeStatus();

    // First time? Go to onboarding/login screen
    if (tabProvider.isFirstTime) {
      _navigateToAuth();
      return;
    }

    // Check subscription status
    final hasTrial = await purchaseService.getTrial();
    final hasPurchase = await purchaseService.getPurchase();

    print('[Home] hasTrial: $hasTrial | hasPurchase: $hasPurchase');

    // If no access, push to Auth
    if (!hasTrial && !hasPurchase) {
      _navigateToVerification(purchaseService);
      return;
    }

    // Allow access to main app
    setState(() => _isLoading = false);
  }

  void _navigateToVerification(PurchaseService purchaseService) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VerificationScreen(
          onFreeTrial: () async {
            // TODO: handle trial logic here if needed
            showDialog(
              context: context,
              barrierDismissible: false, // ⛔️ no tap outside to dismiss
              builder: (context) => WillPopScope(
                onWillPop: () async => false, // ⛔️ block back button
                child: CustomConfirmDialog(
                  isPop: false,
                  children: [SizedBox.shrink()],
                  title: "Enjoy a 7-Day Free Trial",
                  content: "You’ll get full access to all features for 7 days — totally free\n\nWant to start your trial now?",
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
            // TODO: handle purchase logic here if needed
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
