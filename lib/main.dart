import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/Model/cart_item_model.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:paninda/View_Model/ProductProvider.dart';
import 'package:paninda/View_Model/StoreCategoryProvider.dart';
import 'package:paninda/View_Model/TabProvider.dart';
import 'package:paninda/home.dart';
import 'package:provider/provider.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(BatchAdapter());
  Hive.registerAdapter(LoanPersonAdapter());
  Hive.registerAdapter(CartItemAdapter());

  await Hive.openBox<LoanPerson>('loans');
  await Hive.openBox<Product>('products');
  await Hive.openBox('categoryVisibility');
  await Hive.openBox('snapshot');


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => StoreCategoryProvider()),
      ],
      child: const MyApp(),
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
        scaffoldBackgroundColor: Colors.white,          // <- sets screen background
        canvasColor: Colors.white,                      // <- sets modal/sheet background
        dialogBackgroundColor: Colors.white,            // <- sets dialog background
        textTheme: GoogleFonts.workSansTextTheme(),      // <- custom font
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: Home(),
    );
  }
}
