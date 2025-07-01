import 'package:flutter/material.dart';
import 'package:paninda/View/Components/Core/scalable_appbar.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: ScalableAppBar(
        showSearchBar: false,
        title: "Loan",
      ),
      body: const SizedBox(), // Empty body as requested
    );
  }
}
