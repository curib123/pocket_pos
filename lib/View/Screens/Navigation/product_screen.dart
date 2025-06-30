import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';
import 'package:paninda/View/Components/Custom/custom_btn.dart';
import 'package:paninda/View/Components/HelperClass/AppColor.dart';
import 'package:paninda/View/Components/Modal/add_product_modal.dart';

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
      key: _scaffoldKey,
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
          onTap: _openDrawer,
          child: const Icon(
            Icons.notes_rounded,
            size: 30,
          ),
        ),
        title: "Product",

      ),
      body: Stack(
        children: [
          // Scrollable product list
          Padding(
            padding: const EdgeInsets.only(bottom: 70), // space for button
            child: ListView(
              children: const [
                SizedBox(height: 20),
                // Add your product widgets here
                ListTile(title: Text('Product 1')),
                ListTile(title: Text('Product 2')),
                ListTile(title: Text('Product 3')),
                // Add more...
              ],
            ),
          ),

          // Fixed Add Product button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: CustomButton(
                color: AppColor.primary,
                icon: Icons.add_circle_rounded,
                  label: "Add Product",
                  onPressed: () => AddProductModal.show(context)),
            )
          ),
        ],
      ),
    );
  }
}
