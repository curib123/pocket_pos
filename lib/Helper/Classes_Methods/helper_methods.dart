import 'package:flutter/cupertino.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Provider/ProductProvider.dart';
import 'package:pocketpos/Provider/ProductSync.dart';
import 'package:provider/provider.dart';

Future<void> autoSync(BuildContext context) async {
  final syncProvider = Provider.of<ProductSync>(context, listen: false);
  await syncProvider.autoSync(context);
}

Future<bool> HardDeleteProductByID(BuildContext context, String productID) async {
  try {
    final syncProvider = Provider.of<ProductSync>(context, listen: false);
    final success = await syncProvider.HardDeleteProductByID(productID);
    return success;
  } catch (e) {
    print('❌ Failed to hard delete product: $e');
    return false;
  }
}

Future<void> refreshProduct(BuildContext context) async {
  final productProvider = context.read<ProductProvider>();
  await productProvider.initializeProducts();
}


