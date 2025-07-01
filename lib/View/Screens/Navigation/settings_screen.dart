import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(title: Text('Item 1')),
          ],
        ),
      ),
      appBar: ScalableAppBar(
        showSearchBar: false,

        title: "Settings",
      ),
      body: const SizedBox(), // Empty body
    );
  }
}
