import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketpos/Model/loan_item.dart';
import 'package:pocketpos/Model/loose_stock.dart';
import 'package:pocketpos/Model/product_analytics.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/product_stock.dart';
import 'package:pocketpos/Model/stock_log.dart';
import 'package:pocketpos/Provider/AuthProvider.dart';
import 'package:pocketpos/Provider/CartListProvider.dart';
import 'package:pocketpos/Provider/CurrencyProvider.dart';
import 'package:pocketpos/Provider/LooseStockProvider.dart';
import 'package:pocketpos/Provider/ProductAnalyticsProvider.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductSync.dart';
import 'package:pocketpos/Provider/StoreCategoryProvider.dart';
import 'package:pocketpos/Provider/SwitchProvider.dart';
import 'package:pocketpos/Provider/TabProvider.dart';
import 'package:pocketpos/Provider/ProductStockProvider.dart';
import 'package:pocketpos/Provider/VariantProductProvider.dart';
import 'package:pocketpos/home.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(ProductStockAdapter());
  Hive.registerAdapter(LooseStockAdapter());
  Hive.registerAdapter(ProductAnalyticsAdapter());
  Hive.registerAdapter(StockLogAdapter());
  Hive.registerAdapter(StockLogReasonAdapter());
  Hive.registerAdapter(LoanItemAdapter());

  final productBox = await Hive.openBox<Product>('products');
  final analyticsBox = await Hive.openBox<ProductAnalytics>('product_analytics');


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
          ChangeNotifierProvider(create: (_) => ProductStockProvider(productBox)),
          ChangeNotifierProxyProvider<ProductProvider, VariantProductProvider>(
            create: (context) => VariantProductProvider(productBox),
            update: (context, productProvider, previous) =>
            previous!..attachProductProvider(productProvider),
          ),

          ChangeNotifierProvider(create: (_) => LooseStockProvider(productBox)),
          ChangeNotifierProvider(create: (_) => ProductAnalyticsProvider(productBox,analyticsBox)),
          Provider(create: (_) => ProductSync(productBox)),

          ChangeNotifierProvider(create: (_) => StoreCategoryProvider()),
          ChangeNotifierProvider(create: (_) => SwitchProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => CartListProvider(productBox)),
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
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        textTheme: GoogleFonts.workSansTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
