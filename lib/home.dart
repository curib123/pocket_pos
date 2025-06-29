import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/bottom_navigation.dart';
import 'package:provider/provider.dart';
import 'package:paninda/View_Model/TabProvider.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final tabProvider = Provider.of<TabProvider>(context);

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
