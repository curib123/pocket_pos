import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/Model/cart_item_model.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/AuthPaymentProvider.dart';
import 'package:paninda/View_Model/CurrencyProvider.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/PaymentGuideProvider.dart';
import 'package:paninda/View_Model/PaymentProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:paninda/View_Model/SwitchProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:paninda/home.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(BatchAdapter());
  Hive.registerAdapter(LoanPersonAdapter());
  Hive.registerAdapter(CartItemAdapter());

  // Open boxes
  await Hive.openBox<LoanPerson>('loans');
  await Hive.openBox<Product>('products');
  await Hive.openBox('categoryVisibility');
  await Hive.openBox('snapshot');
  await Hive.openBox('checkout_profits');
  await Hive.openBox('settings_currency');

  const supabaseUrl = 'https://ftqrtildlcgfmfqczwle.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0cXJ0aWxkbGNnZm1mcWN6d2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODU0MDIsImV4cCI6MjA2NzI2MTQwMn0.Q3I5PojjIcH4MoOQHA98BQG28HY_EatpMcElc_iXP-s';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TabProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => LoanProvider()),
          ChangeNotifierProvider(create: (_) => StoreCategoryProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => AuthPaymentProvider()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
          ChangeNotifierProvider(create: (_) => PaymentGuideProvider ()),
          ChangeNotifierProvider(create: (_) => SwitchProvider ()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Paninda Stock and Inventory Mobile App",
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        textTheme: GoogleFonts.workSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
