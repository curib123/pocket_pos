import 'dart:async';

import '../../Model/product_model.dart';
import 'offline_database.dart';

/// In-memory read cache backed exclusively by SQLite.
///
/// Providers use this store for synchronous reads while every mutation is
/// persisted through [OfflineDatabase] before observers are notified.
class ProductStore {
  ProductStore._();

  static final ProductStore instance = ProductStore._();

  final OfflineDatabase _database = OfflineDatabase.instance;
  final Map<String, Product> _products = <String, Product>{};
  final StreamController<void> _changes =
      StreamController<void>.broadcast(sync: true);

  bool _initialized = false;

  Iterable<Product> get values => List<Product>.unmodifiable(_products.values);

  Iterable<String> get keys => List<String>.unmodifiable(_products.keys);

  bool containsKey(String id) => _products.containsKey(id);

  Product? get(String id) => _products[id];

  Stream<void> watch() => _changes.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    await reload(notify: false);
    _initialized = true;
  }

  Future<void> reload({bool notify = true}) async {
    final products = await _database.readProducts();
    _products
      ..clear()
      ..addEntries(products.map((product) => MapEntry(product.id, product)));
    if (notify) _changes.add(null);
  }

  Future<void> put(String id, Product product) async {
    if (id != product.id) {
      throw ArgumentError.value(id, 'id', 'must match product.id');
    }
    await _database.upsertProduct(product);
    _products[id] = product;
    _changes.add(null);
  }

  Future<void> clear() async {
    await _database.clearProducts();
    _products.clear();
    _changes.add(null);
  }
}
