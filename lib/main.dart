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
import 'package:nextpos/Provider/OfflineDataProvider.dart';
import 'package:nextpos/core/data/offline_database.dart';
import 'package:nextpos/Provider/OfflineSyncProvider.dart';

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

  // SQLite is the durable offline-first store and sync outbox. Hive remains
  // available during the migration so existing screens keep their behavior.
  await OfflineDatabase.instance.database;

  // Secure Storage
  final storage = SecureStorageService();

  // 🔥 Replace dotenv with direct constants
  const supabaseUrl = "YOUR_SUPABASE_URL";
  const supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";

  // Cloud sync is optional. A production build supplies these through a
  // secure configuration layer; an offline build must still start normally.
  if (supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty) {
    final existingKey = await storage.readSupabaseKey();
    if (existingKey == null || existingKey.isEmpty) {
      await storage.saveSupabaseKey(supabaseAnonKey);
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

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
          ChangeNotifierProvider(create: (_) => OfflineDataProvider()),
          ChangeNotifierProvider(create: (_) => OfflineSyncProvider()),
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
