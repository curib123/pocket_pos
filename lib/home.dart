import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:paninda/View/Components/Core/bottom_navigation.dart';
import 'package:paninda/View/Components/Custom/handleActivationCheck.dart';
import 'package:paninda/View/Components/Custom/handle_payment_verification.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Components/HelperClass/ProfitHelper.dart';
import 'package:paninda/View/Screens/Navigation/signin_screen.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/PaymentProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:provider/provider.dart';

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
    Future.delayed(Duration.zero,() async {
     await _initializeApp();
     await checkIfTrialExpired(context);
      await ProfitHelper.syncTwoWay();
    });
  }

  Future<void> _initializeApp() async {
    try {
      final tabProvider = Provider.of<TabProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);

      await tabProvider.loadFirstTimeStatus();
      await paymentProvider.fetchPayments();

      final latestPayment = paymentProvider.payments.isNotEmpty
          ? Map<String, dynamic>.from(paymentProvider.payments.first)
          : <String, dynamic>{};

      if (latestPayment.isNotEmpty &&
          (latestPayment['payment_status']?.toString().isNotEmpty ?? false) &&
          latestPayment['payment_status'].toString() != "approved") {
        final paymentProofPublicUrl = paymentProvider.getLatestPaymentProofUrl();
        _startScreen = HandlePaymentVerification(
          latestPayment: latestPayment,
          paymentProofPublicUrl: paymentProofPublicUrl,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❗ Error during app initialization: $e');
      debugPrint('$stackTrace');
      final tabProvider = Provider.of<TabProvider>(context, listen: false);
      final authPaymentProvider = Provider.of<AuthPaymentProvider>(context, listen: false);

      if (tabProvider.isFirstTime) {
        final userDetails = await authPaymentProvider.readUserDetails();
        final email = userDetails['email'];

        if (email == null || email.toString().isEmpty) {
          _startScreen = const SigninScreen();
        } else {
          // ✅ No need to assign a widget; just navigate.
          if (context.mounted) {
            await handleActivationCheck(context);
          }
        }
      }
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

    if (_startScreen != null) {
      return _startScreen!;
    }

    return Scaffold(
      body: tabProvider.screens[tabProvider.currentIndex],
      bottomNavigationBar: BottomNavigation(
        currentIndex: tabProvider.currentIndex,
        onTabSelected: (index) {
          tabProvider.setTab(index);
        },
      ),
    );
  }
}
