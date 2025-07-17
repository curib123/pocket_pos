import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_stock_inventory/Model/loose_stock.dart';
import 'package:mobile_stock_inventory/Model/product_analytics.dart';
import 'package:mobile_stock_inventory/Model/product_model.dart';
import 'package:mobile_stock_inventory/Model/product_stock.dart';
import 'package:mobile_stock_inventory/Model/stock_log.dart';
import 'package:mobile_stock_inventory/Provider/AuthProvider.dart';
import 'package:mobile_stock_inventory/Provider/CartProvider.dart';
import 'package:mobile_stock_inventory/Provider/CurrencyProvider.dart';
import 'package:mobile_stock_inventory/Provider/LooseStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductAnalyticsProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductSync.dart';
import 'package:mobile_stock_inventory/Provider/StockLogProvider.dart';
import 'package:mobile_stock_inventory/Provider/StoreCategoryProvider.dart';
import 'package:mobile_stock_inventory/Provider/SwitchProvider.dart';
import 'package:mobile_stock_inventory/Provider/TabProvider.dart';
import 'package:mobile_stock_inventory/Provider/ProductStockProvider.dart';
import 'package:mobile_stock_inventory/Provider/VariantProductProvider.dart';
import 'package:mobile_stock_inventory/View/Components/SnackbarService.dart';
import 'package:mobile_stock_inventory/home.dart';
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
          ChangeNotifierProvider(create: (_) => VariantProductProvider(productBox)),
          ChangeNotifierProvider(create: (_) => LooseStockProvider(productBox)),
          ChangeNotifierProvider(create: (_) => ProductAnalyticsProvider(productBox,analyticsBox)),
          Provider(create: (_) => ProductSync(productBox)),
          ChangeNotifierProxyProvider<ProductSync, StockLogProvider>(
            create: (_) => StockLogProvider(productBox),
            update: (_, sync, provider) {
              provider!.attachSync(sync);
              return provider;
            },
          ),


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
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
