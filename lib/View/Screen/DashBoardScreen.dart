import 'package:flutter/material.dart';
import 'package:pocketpos/Helper/Classes_Methods/helper_methods.dart';
import 'package:pocketpos/View/Components/Alert/showResultDialogAfterSync.dart';
import 'package:pocketpos/View/Components/Widgets/AppDrawer.dart';
import 'package:pocketpos/View/Components/Widgets/SearchAndCartRow.dart';

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
      autoSync(context);
      refreshProduct(context);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: SearchAndCartAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          showResultDialogAfterAsync(
            context: context,
            asyncMethod: () async {
              await autoSync(context);
              await refreshProduct(context);
              return "Products refreshed and synced ✨";
            },
            onComplete: () {

            } ,
          );
        },
        child: ListView(
          children: [
            Center(
              child: Text("Welcome"),
            ),
          ],
        ),
      ),
    );
  }
}
