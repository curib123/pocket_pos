import 'package:flutter/cupertino.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductSync.dart';
import 'package:provider/provider.dart';
Future<void> autoSync(BuildContext context) async {
  final syncProvider = Provider.of<ProductSync>(context, listen: false);
  final productProvider = Provider.of<ProductProvider>(context, listen: false);

  await syncProvider.autoSync(
    productProvider.getAllProductsInBox(),
        (product) async => await productProvider.silentUpsertProduct(product),
  );
}

Future<void> refreshProduct(BuildContext context) async {
  final productProvider = context.read<ProductProvider>();
  await productProvider.initializeProducts();
}


