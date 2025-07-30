import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/product_stock.dart';
import 'package:pocketpos/Model/loose_stock.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/Model/loan_item.dart';

// Providers
import 'package:pocketpos/Provider/AuthProvider.dart';
import 'package:pocketpos/Provider/CartListProvider.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/LoanProvider.dart';
import 'package:pocketpos/Provider/LogProvider.dart';
import 'package:pocketpos/Provider/LooseStockProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductStockProvider.dart';
import 'package:pocketpos/Provider/ProductSync.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/Provider/SwitchProvider.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/Provider/VariantProductProvider.dart';

// UI
import 'package:pocketpos/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive and register adapters
  await Hive.initFlutter();
  Hive
    ..registerAdapter(ProductAdapter())
    ..registerAdapter(ProductStockAdapter())
    ..registerAdapter(LooseStockAdapter())
    ..registerAdapter(StockLogAdapter())
    ..registerAdapter(StockLogReasonAdapter())
    ..registerAdapter(LoanItemAdapter());

  // Open Boxes
  await Hive.openBox<Product>('products');
  await Hive.openBox('categoryVisibility');
  await Hive.openBox('settings_currency');

  // Supabase Init
  const supabaseUrl = 'https://ftqrtildlcgfmfqczwle.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0cXJ0aWxkbGNnZm1mcWN6d2xlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2ODU0MDIsImV4cCI6MjA2NzI2MTQwMn0.Q3I5PojjIcH4MoOQHA98BQG28HY_EatpMcElc_iXP-s';
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TabProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => ProductStockProvider()),
          ChangeNotifierProvider(create: (_) => LooseStockProvider()),
          ChangeNotifierProvider(create: (_) => StoreCategoryProvider()),
          ChangeNotifierProvider(create: (_) => SwitchProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => LoanProvider()),
          ChangeNotifierProvider(create: (_) => LogProvider()),
          ChangeNotifierProvider(create: (_) => CartListProvider()),
          ChangeNotifierProxyProvider<ProductProvider, VariantProductProvider>(
            create: (_) => VariantProductProvider(),
            update: (_, productProvider, previous) =>
            previous!..attachProductProvider(productProvider),
          ),
          Provider(create: (_) => ProductSync()),
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
      title: "Mobile POS & Inventory App",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        textTheme: GoogleFonts.workSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          surface: Colors.white,
        ),
      ),
      home: const Home(),
    );
  }
}
