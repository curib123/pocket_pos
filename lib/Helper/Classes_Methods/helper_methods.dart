import 'package:flutter/cupertino.dart';
import 'package:nextpos/Provider/ProductProvider.dart';
import 'package:nextpos/Provider/ProductSync.dart';
import 'package:provider/provider.dart';

/// Safely syncs products between local and Supabase
Future<void> autoSync(BuildContext context) async {
  try {
    final syncProvider = Provider.of<ProductSync>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    await syncProvider.autoSync(
      productProvider.getAllProductsInBox(),
          (product) async => await productProvider.silentUpsertProduct(product),
    );

  } catch (e) {
    // You can log or handle errors silently here
  }
}


