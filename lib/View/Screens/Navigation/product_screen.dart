import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';

class ProductScreen extends StatelessWidget {
  ProductScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    if (_scaffoldKey.currentState != null) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key here
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
        leading: GestureDetector(
          onTap: _openDrawer, // Use method tied to global key
          child: const Icon(
            Icons.notes_rounded,
            size: 30,
          ),
        ),
        title: "Product",
      ),
      body: ListView(
        children: const [
          // Add your product list widgets here
        ],
      ),
    );
  }
}
