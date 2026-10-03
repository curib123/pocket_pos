import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:nextpos/Helper/Database/SecureStorageServices.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers
import 'package:nextpos/Provider/AuthProvider.dart';
import 'package:nextpos/Provider/CurrencyProvider.dart';
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
import 'package:nextpos/core/ads/ad_service.dart';
import 'package:nextpos/core/data/offline_database.dart';
import 'package:nextpos/core/data/product_store.dart';
import 'package:nextpos/core/theme/app_theme.dart';
import 'package:nextpos/Provider/OfflineSyncProvider.dart';

// UI
import 'package:nextpos/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite is the only local persistence layer. Initialize the database and
  // ProductStore before Providers are created.
  await OfflineDatabase.instance.database;
  await ProductStore.instance.initialize();

  // Ads never block the offline-first startup path.
  unawaited(StartIoAdService.instance.initialize());

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
          ChangeNotifierProvider(create: (_) => LogProvider()),
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
      title: 'Pocket Inventory',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Home(),
    );
  }
}
