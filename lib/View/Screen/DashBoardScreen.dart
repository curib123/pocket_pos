import 'package:flutter/material.dart';
import 'package:mobile_pos_inventory/View/Components/SearchAndCartRow.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAndCartAppBar(),
      body: Center(
        child: Text("Welcome"),
      ),
    );
  }
}
