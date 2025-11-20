import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketpos/Helper/Database/SecureStorageServices.dart';
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

  // Init Hive
  await Hive.initFlutter();
  Hive
    ..registerAdapter(ProductAdapter())
    ..registerAdapter(ProductStockAdapter())
    ..registerAdapter(LooseStockAdapter())
    ..registerAdapter(StockLogAdapter())
    ..registerAdapter(StockLogReasonAdapter())
    ..registerAdapter(LoanItemAdapter());

  await Hive.openBox<Product>('products');
  await Hive.openBox('categoryVisibility');
  await Hive.openBox('settings_currency');

  // Secure Storage
  final storage = SecureStorageService();

  // 🔥 Replace dotenv with direct constants
  const supabaseUrl = "YOUR_SUPABASE_URL";
  const supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception("Supabase URL or key is missing!");
  }

  // Save to secure storage if not existing
  final existingKey = await storage.readSupabaseKey();
  if (existingKey == null || existingKey.isEmpty) {
    await storage.saveSupabaseKey(supabaseAnonKey);
  }

  // Supabase init
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
      title: "NextPOS AI",
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
