import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/product_stock.dart';
import 'package:nextpos/Model/loose_stock.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/Model/loan_item.dart';

// Providers
import 'package:nextpos/Provider/AuthProvider.dart';
import 'package:nextpos/Provider/CartListProvider.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
import 'package:nextpos/Provider/LoanProvider.dart';
import 'package:nextpos/Provider/LogProvider.dart';
import 'package:nextpos/Provider/LooseStockProvider.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductStockProvider.dart';
import 'package:nextpos/Provider/ProductSync.dart';
import 'package:nextpos/Provider/StoreCategoryProvider.dart';
import 'package:nextpos/Provider/SwitchProvider.dart';
import 'package:nextpos/Provider/TabProvider.dart';
import 'package:nextpos/Provider/VariantProductProvider.dart';

// UI
import 'package:nextpos/home.dart';

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
