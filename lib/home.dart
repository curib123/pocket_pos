import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:paninda/View/Components/Core/bottom_navigation.dart';
import 'package:paninda/View/Components/Custom/handle_payment_verification.dart';
import 'package:paninda/View/Components/Custom/handleActivationCheck.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Screens/Navigation/signin_screen.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/PaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = true;
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _initApp();
    checkIfTrialExpired(context);
  }

  /// ✅ Initialize App State & Determine Initial Screen
  Future<void> _initApp() async {
    try {
      final tabProvider = Provider.of<TabProvider>(context, listen: false);
      final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      await tabProvider.loadFirstTimeStatus();
      await paymentProvider.fetchPayments();

     final Map<String, dynamic>  latestPayment = paymentProvider.payments.isNotEmpty
          ? paymentProvider.payments.first
          : {};

      print(  latestPayment['payment_status'].toString());
      final paymentProofPublicUrl = paymentProvider.getLatestPaymentProofUrl();


      // ✅ Priority 1: Payment Verification
      if (latestPayment.isNotEmpty &&
          latestPayment['payment_status'].toString().isNotEmpty) {
        _startScreen = HandlePaymentVerification(latestPayment: latestPayment, paymentProofPublicUrl: paymentProofPublicUrl,);
      }
      // ✅ Priority 2: First-Time User Check
      else if (tabProvider.isFirstTime) {
        final userDetails = await authPaymentProvider.readUserDetails();
        final email = userDetails['email'];

        if (email == null || email.isEmpty) {
          _startScreen = const SigninScreen();
        } else {
          final card = await handleActivationCheck(context, isReturn: true);
          _startScreen = Scaffold(
            body: Center(child: card),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Show First-Time Screen or Payment Verification if available
    if (_startScreen != null) {
      return _startScreen!;
    }

    // ✅ Main App Screen
    final currentScreen = tabProvider.screens[tabProvider.currentIndex];

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigation(
        currentIndex: tabProvider.currentIndex,
        onTabSelected: (index) => tabProvider.setTab(index),
      ),
    );
  }
}
