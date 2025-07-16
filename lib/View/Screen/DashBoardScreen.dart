import 'package:flutter/material.dart';
import 'package:mobile_stock_inventory/Provider/ProductSyncProvider.dart';
import 'package:mobile_stock_inventory/View/Components/SearchAndCartRow.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero,() async {
      ///sync local to database vice versa
      final syncProvider = Provider.of<ProductSyncProvider>(context, listen: false);
      await syncProvider.autoSync();


    });
  }
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
