import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:retailpos/Model/loose_stock.dart';
import 'package:retailpos/Model/product_analytics.dart';
import 'package:retailpos/Model/product_model.dart';
import 'package:retailpos/Model/product_stock.dart';
import 'package:retailpos/Model/stock_log.dart';
import 'package:retailpos/Provider/AuthProvider.dart';
import 'package:retailpos/Provider/CartListProvider.dart';
import 'package:retailpos/Provider/CurrencyProvider.dart';
import 'package:retailpos/Provider/LooseStockProvider.dart';
import 'package:retailpos/Provider/ProductAnalyticsProvider.dart';
import 'package:retailpos/Provider/ProductProvider.dart';
import 'package:retailpos/Provider/ProductSync.dart';
import 'package:retailpos/Provider/StoreCategoryProvider.dart';
import 'package:retailpos/Provider/SwitchProvider.dart';
import 'package:retailpos/Provider/TabProvider.dart';
import 'package:retailpos/Provider/ProductStockProvider.dart';
import 'package:retailpos/Provider/VariantProductProvider.dart';
import 'package:retailpos/home.dart';
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
