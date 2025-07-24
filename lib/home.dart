import 'package:flutter/material.dart';
import 'package:pocketpos/View/Screen/AuthScreen.dart';
import 'package:provider/provider.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/View/Components/Widgets/BottomNavigation.dart';
import 'package:pocketpos/View/Screen/DashBoardScreen.dart';    // <-- Example main screen

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
    checkFirstTime();
  }

  Future<void> checkFirstTime() async {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    await tabProvider.loadFirstTimeStatus();

    if (tabProvider.isFirstTime) {
      // Delay is optional: gives time for animations or splash
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      });
    } else {
      setState(() => _isLoading = false);
    }
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
