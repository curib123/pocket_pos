import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_pos_inventory/Model/loose_stock.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/product_stock.dart';
import 'package:mobile_pos_inventory/Model/stock_log.dart';
import 'package:mobile_pos_inventory/Provider/AuthProvider.dart';
import 'package:mobile_pos_inventory/Provider/CartProvider.dart';
import 'package:mobile_pos_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_pos_inventory/Provider/ProductProvider.dart';
import 'package:mobile_pos_inventory/Provider/ProductSyncProvider.dart';
import 'package:mobile_pos_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_pos_inventory/Provider/SwitchProvider.dart';
import 'package:mobile_pos_inventory/Provider/TabProvider.dart';
import 'package:mobile_pos_inventory/View/Components/SnackbarService.dart';
import 'package:mobile_pos_inventory/home.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductStockAdapter());
  Hive.registerAdapter(LooseStockAdapter());
  Hive.registerAdapter(StockLogAdapter());

  final productBox = await Hive.openBox<Product>('products');

  await Hive.openBox('categoryVisibility');
  await Hive.openBox('settings_currency');

  const supabaseUrl = 'https://ftqrtildlcgfmfqczwle.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0cXJ0aWxkbGNnZm1mcWN6d2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODU0MDIsImV4cCI6MjA2NzI2MTQwMn0.Q3I5PojjIcH4MoOQHA98BQG28HY_EatpMcElc_iXP-s';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TabProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider(productBox)),
          Provider(create: (_) => ProductSyncProvider(productBox)),
          ChangeNotifierProvider(create: (_) => StoreCategoryProvider()),
          ChangeNotifierProvider(create: (_) => SwitchProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
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
      scaffoldMessengerKey: SnackbarService.messengerKey,
      debugShowCheckedModeBanner: false,
      title: "Mobile POS & Inventory App",
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
