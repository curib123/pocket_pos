import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/bottom_navigation.dart';
import 'package:paninda/View/Components/HelperClass/CheckTrialExpired.dart';
import 'package:paninda/View/Screens/Navigation/signin_screen.dart';
import 'package:paninda/View/Screens/Navigation/signup_screen.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:provider/provider.dart';
import 'package:paninda/View_Model/TabProvider.dart';

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
    _loadFirstTimeFlag();
    checkIfTrialExpired(context);

  }

  Future<void> _loadFirstTimeFlag() async {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    await tabProvider.loadFirstTimeStatus(); // Load first_time status manually
    setState(() {
      _isLoading = false;
    });
  }





  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (tabProvider.isFirstTime) {
      return const SigninScreen(); // First-time install screen
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
