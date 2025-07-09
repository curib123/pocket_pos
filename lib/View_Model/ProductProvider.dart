import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/View/Components/HelperClass/ProfitHelper.dart';
import 'package:paninda/View/Components/HelperClass/supabase_service.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DateRangeType { day, week, month, year }

class ProductProvider with ChangeNotifier {
  final Box<Product> _productBox = Hive.box<Product>('products');
  List<Product> get products => _productBox.values.toList();
  final _supabaseService = SupabaseService();
  final supabase = Supabase.instance.client;

  int _prevProductCount = 0;
  int _prevTotalQuantity = 0;
  DateTime _lastSnapshotDate = DateTime.now().subtract(const Duration(days: 1));

  ProductProvider() {
    loadSnapshot();
  }


  // CART
  final Map<Product, int> _cartItems = {};
  final Map<Product, double> _kiloCartItems = {};

  Map<Product, int> getCartItems() => _cartItems;
  Map<Product, double> getKiloCartItems() => _kiloCartItems;
  int getCartItemCount() => _cartItems.length;

  final _secureStorage = const FlutterSecureStorage();
  DateTime? _lastSyncTime;



  /// Load last sync time from secure storage
  Future<void> loadLastSyncTime() async {
    final stored = await _secureStorage.read(key: 'lastProductSync');
    if (stored != null) {
      _lastSyncTime = DateTime.tryParse(stored);
    }
  }

  /// Save current time as last sync time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _secureStorage.write(key: 'lastProductSync', value: time.toIso8601String());
    _lastSyncTime = time;
  }

  /// Insert products to database
  Future<void> insertOrUpdateProductsAndProfitsToDatabase() async {
    await _supabaseService.insertProducts(products);
  }

  /// Fetch products by user from server
  Future<List<Product>> getProductsByUserFromDatabase(String userId) async {
    return await _supabaseService.getProductsByUser();
  }

  /// Main Sync Method (handles both download & upload)
  Future<void> syncProductsWithServer() async {
    try {
      await loadLastSyncTime();


      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in.');
      }

      // Step 1: Fetch all products from server
      final serverProducts = await getProductsByUserFromDatabase(userId);


      // Step 2: Merge server products into local storage
      for (var serverProduct in serverProducts) {
        final localProduct = getProductById(serverProduct.id);

        if (localProduct == null) {
          addProduct(serverProduct);
        } else if (localProduct.lastModified.isBefore(serverProduct.lastModified)) {
          updateProduct(serverProduct.id, serverProduct);
        }
      }


      // Step 3: Upload local changes after last sync
      final updatedProducts = products.where((p) =>
      _lastSyncTime == null || p.lastModified.isAfter(_lastSyncTime!)).toList();

      if (updatedProducts.isNotEmpty) {
        await _supabaseService.insertProducts(updatedProducts);
      }

      // Step 4: Save sync time after successful sync
      await saveLastSyncTime(DateTime.now());

      notifyListeners();
    } catch (e) {
      debugPrint('Error during product sync: $e');
      // Optionally: show a user-friendly error here
    }
  }

  void addToCart(Product product, int quantity, double kiloQuantity) {
    if (_cartItems.containsKey(product)) {
      _cartItems[product] = _cartItems[product]! + quantity;
      _kiloCartItems[product] = (_kiloCartItems[product] ?? 0.0) + kiloQuantity;
    } else {
      _cartItems[product] = quantity;
      _kiloCartItems[product] = kiloQuantity;
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cartItems.remove(product);
    _kiloCartItems.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _kiloCartItems.clear();
    notifyListeners();
  }

  // PRODUCT ACTIONS

  bool productExists(String id) => _productBox.containsKey(id);

  Product? getProductById(String id) => _productBox.get(id);

  Product? getProductByName(String name) {
    try {
      return _productBox.values.firstWhere((prod) => prod.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    final lower = query.toLowerCase();
    return _productBox.values.where((product) {
      return product.id.toLowerCase().contains(lower) ||
          product.name.toLowerCase().contains(lower);
    }).toList();
  }

  List<Product> getProductsByCategory(String category) {
    return _productBox.values
        .where((product) => product.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  int getProductCountByCategory(String category) {
    return _productBox.values
        .where((product) => product.category.toLowerCase() == category.toLowerCase())
        .length;
  }

  void addProduct(Product product) {
    if (!productExists(product.id)) {
      product.lastModified = DateTime.now();  // UPDATED
      _productBox.put(product.id, product);
      notifyListeners();
    }
  }

  void updateProduct(String id, Product updatedProduct) {
    if (productExists(id)) {
      updatedProduct.lastModified = DateTime.now();  // UPDATED
      _productBox.put(id, updatedProduct);
      notifyListeners();
    }
  }

  void removeProduct(String id) {
    _productBox.delete(id);
    notifyListeners();
  }

  void clearProducts() {
    _productBox.clear();
    notifyListeners();
  }

  List<Batch> getBatchesForProduct(String productId) {
    return getProductById(productId)?.batches ?? [];
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void restockProduct(String id, double quantity, double kiloQuantity, {DateTime? date}) {
    final product = getProductById(id);
    if (product != null) {
      final targetDate = date ?? DateTime.now();

      final index = product.batches.indexWhere((batch) => isSameDate(batch.date, targetDate));

      if (index != -1) {
        product.batches[index].quantity += quantity;
        product.batches[index].kiloQuantity += kiloQuantity;
      } else {
        product.batches.add(Batch(
          date: targetDate,
          quantity: quantity,
          kiloQuantity: kiloQuantity,
        ));
      }

      product.lastModified = DateTime.now();  // UPDATED
      product.save();
      notifyListeners();
    }
  }

  void useStockFIFO(String id, double quantityToUse) {
    final product = getProductById(id);
    if (product == null) return;

    double remaining = quantityToUse;
    product.batches.sort((a, b) => a.date.compareTo(b.date));

    for (var batch in product.batches) {
      if (remaining <= 0) break;
      if (batch.quantity >= remaining) {
        batch.quantity -= remaining;
        remaining = 0;
      } else {
        remaining -= batch.quantity;
        batch.quantity = 0;
      }
    }

    product.batches.removeWhere((b) => b.quantity <= 0 && b.kiloQuantity <= 0);
    product.lastModified = DateTime.now();  // UPDATED
    product.save();
    notifyListeners();
  }

  void useStockFIFOKilos(String id, double kiloToUse) {
    final product = getProductById(id);
    if (product == null) return;

    double remaining = kiloToUse;
    product.batches.sort((a, b) => a.date.compareTo(b.date));

    for (var batch in product.batches) {
      if (remaining <= 0) break;
      if (batch.kiloQuantity >= remaining) {
        batch.kiloQuantity -= remaining;
        remaining = 0;
      } else {
        remaining -= batch.kiloQuantity;
        batch.kiloQuantity = 0;
      }
    }

    product.batches.removeWhere((b) => b.quantity <= 0 && b.kiloQuantity <= 0);
    product.lastModified = DateTime.now();  // UPDATED
    product.save();
    notifyListeners();
  }

  void updateProductQuantityManually(String id, double quantity, double kiloQuantity) {
    final product = getProductById(id);
    if (product != null) {
      product.batches = [Batch(date: DateTime.now(), quantity: quantity, kiloQuantity: kiloQuantity)];
      product.lastModified = DateTime.now();  // UPDATED
      product.save();
      notifyListeners();
    }
  }

  void removeAllBatches(String id) {
    final product = getProductById(id);
    if (product != null) {
      product.batches.clear();
      product.lastModified = DateTime.now();  // UPDATED
      product.save();
      notifyListeners();
    }
  }

  void removeExpiredBatches(String id, DateTime Function(Batch) getExpiryDate) {
    final product = getProductById(id);
    if (product != null) {
      product.batches.removeWhere((batch) => getExpiryDate(batch).isBefore(DateTime.now()));
      product.lastModified = DateTime.now();  // UPDATED
      product.save();
      notifyListeners();
    }
  }

  void removeBatchFromProduct({
    required String productId,
    required DateTime batchDate,
  }) {
    final product = getProductById(productId);
    if (product != null) {
      final batchToRemove = product.batches.firstWhere(
            (batch) => batch.date == batchDate,
      );
      if (batchToRemove != null) {
        product.batches.remove(batchToRemove);
        product.lastModified = DateTime.now();  // UPDATED
        product.save();
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>?> checkoutCart({
    required List<Map<String, dynamic>> cartItems,
    required bool isLoan,
    double buyerCash = 0,
    String borrowerName = '',
    LoanProvider? loanProvider,
  }) async {
    double total = 0;
    double totalProfit = 0;
    List<Map<String, dynamic>> receipt = [];

    for (var item in cartItems) {
      final productId = item['productId'];
      final quantity = item['quantity'];
      final isKilo = item['isKilo'] ?? false;
      final product = getProductById(productId);
      if (product == null) return null;

      final available = isKilo ? product.totalKilos : product.totalSacks;
      if (quantity > available) return null;

      final itemTotal = quantity * product.retailPrice;
      final itemCost = quantity * product.costPrice;
      final itemProfit = itemTotal - itemCost;

      total += itemTotal;
      totalProfit += itemProfit;

      receipt.add({
        'productId': product.id,
        'productName': product.name,
        'unit': isKilo ? 'kilo' : product.unit,
        'quantity': quantity,
        'unitPrice': product.retailPrice,
        'total': itemTotal,
        'profit': itemProfit,
      });
    }

    final now = DateTime.now();

    if (!isLoan) {
      if (buyerCash < total) return null;

      for (var item in cartItems) {
        final isKilo = item['isKilo'] ?? false;
        isKilo
            ? useStockFIFOKilos(item['productId'], item['quantity'])
            : useStockFIFO(item['productId'], item['quantity']);
      }


    await ProfitHelper.saveProfit(totalProfit);

      return {
        'items': receipt,
        'grandTotal': total,
        'cashGiven': buyerCash,
        'change': buyerCash - total,
        'profit': totalProfit,
        'timestamp': now,
        'status': 'Paid',
      };
    }

    if (isLoan) {
      if (loanProvider == null || borrowerName.trim().isEmpty) return null;

      for (var item in cartItems) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        final isKilo = item['isKilo'] ?? false;
        final product = getProductById(productId);
        if (product == null) continue;

        isKilo
            ? useStockFIFOKilos(productId, quantity)
            : useStockFIFO(productId, quantity);

        loanProvider.addLoan(
          LoanPerson(
            name: borrowerName,
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            totalAmount: quantity * product.retailPrice,
            date: now,
            isPaid: false,
          ),
        );
      }

      await ProfitHelper.saveProfit(totalProfit);


      return {
        'items': receipt,
        'grandTotal': total,
        'profit': totalProfit,
        'timestamp': now,
        'borrower': borrowerName,
        'status': 'Loan',
      };
    }

    return null;
  }

  // INVENTORY METRICS
  double get totalInventorySacks => products.fold(0, (sum, p) => sum + p.totalSacks);
  double get totalInventoryKilos => products.fold(0, (sum, p) => sum + p.totalKilos);
  double get totalInventoryCostValue => products.fold(0, (sum, p) => sum + p.totalCostValueSack + p.totalCostValueKilo);
  double get totalInventoryRetailValue => products.fold(0, (sum, p) => sum + p.totalRetailValueSack + p.totalRetailValueKilo);
  double get allProductsTotalProfit => products.fold(0, (sum, p) => sum + (p.totalRetailValueSack - p.totalCostValueSack) + (p.totalRetailValueKilo - p.totalCostValueKilo));
  int get totalProductCount => _productBox.length;
  int get totalBatchCount => products.fold(0, (sum, p) => sum + p.batches.length);

  bool isStockLow(String id, double threshold) {
    final product = getProductById(id);
    if (product == null) return false;
    return product.totalSacks < threshold;
  }

  List<Map<String, dynamic>> getProfitPerBatch(Product product) {
    return product.batches.map((b) {
      final sackProfit = b.quantity * (product.retailPrice - product.costPrice);
      final kiloProfit = b.kiloQuantity * (product.retailPrice - product.costPrice);
      return {
        'date': b.date,
        'quantity': b.quantity,
        'kiloQuantity': b.kiloQuantity,
        'profitSacks': sackProfit,
        'profitKilos': kiloProfit,
      };
    }).toList();
  }

  final dateFormat = DateFormat('MMM d, yyyy');

  int getIsoWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = date.difference(firstMonday).inDays;
    return ((diff / 7).ceil()).clamp(1, 53);
  }

  Map<String, double> getProfitBy(DateRangeType type) {
    final Map<String, double> grouped = {};

    for (final p in products) {
      for (final b in p.batches) {
        final profit = (b.quantity + b.kiloQuantity) * (p.retailPrice - p.costPrice);
        final date = b.date;
        late String key;

        switch (type) {
          case DateRangeType.day:
            key = dateFormat.format(date); // e.g. "Jul 9, 2025"
            break;
          case DateRangeType.week:
            final weekNumber = getIsoWeekNumber(date);
            key = "Week $weekNumber of ${DateFormat('yyyy').format(date)}"; // e.g. "Week 28 of 2025"
            break;
          case DateRangeType.month:
            key = DateFormat('MMM yyyy').format(date); // e.g. "Jul 2025"
            break;
          case DateRangeType.year:
            key = date.year.toString();
            break;
        }

        grouped[key] = (grouped[key] ?? 0) + profit;
      }
    }

    return grouped;
  }

  Map<String, double> getCheckoutProfitBy(DateRangeType rangeType) {
    final Map<String, double> grouped = {};

    for (var record in ProfitHelper.profitBox.values) {
      final profitRaw = record['profit'];

      double profit;
      if (profitRaw is num) {
        profit = profitRaw.toDouble();
      } else if (profitRaw is List) {
        // If somehow stored as List, you can sum it or just skip:
        profit = 0.0;  // Or sum it if needed: profitRaw.fold(0.0, (sum, e) => sum + (e as num))
      } else {
        profit = 0.0;
      }

      final timestampStr = record['timestamp'];
      final date = DateTime.tryParse(timestampStr);
      if (date == null) continue;

      late String key;
      switch (rangeType) {
        case DateRangeType.day:
          key = dateFormat.format(date);
          break;
        case DateRangeType.week:
          final week = getIsoWeekNumber(date);
          key = "Week $week of ${date.year}";
          break;
        case DateRangeType.month:
          key = DateFormat('MMM yyyy').format(date);
          break;
        case DateRangeType.year:
          key = date.year.toString();
          break;
      }

      grouped[key] = (grouped[key] ?? 0) + profit;
    }

    return grouped;
  }


  Map<String, double>? getCartTotalsWithProfit(List<Map<String, dynamic>> cartItems) {
    double totalRetail = 0;
    double totalCost = 0;

    for (var item in cartItems) {
      final productId = item['productId'];
      final quantity = item['quantity'];
      final isKilo = item['isKilo'] ?? false;

      final product = getProductById(productId);
      if (product == null) return null;

      totalRetail += quantity * product.retailPrice;
      totalCost += quantity * product.costPrice;
    }

    return {
      'totalRetail': totalRetail,
      'totalCost': totalCost,
      'profit': totalRetail - totalCost,
    };
  }

  // SNAPSHOT — HIVE REPLACEMENT
  Future<void> loadSnapshot() async {
    final box = await Hive.openBox('snapshot');
    _prevProductCount = box.get('prevProductCount', defaultValue: 0);
    _prevTotalQuantity = box.get('prevTotalQuantity', defaultValue: 0);
    final savedDate = box.get('lastSnapshotDate');
    _lastSnapshotDate = savedDate != null
        ? DateTime.tryParse(savedDate) ?? DateTime.now().subtract(const Duration(days: 1))
        : DateTime.now().subtract(const Duration(days: 1));
  }

  Future<void> _saveSnapshot() async {
    final box = await Hive.openBox('snapshot');
    await box.put('prevProductCount', _prevProductCount);
    await box.put('prevTotalQuantity', _prevTotalQuantity);
    await box.put('lastSnapshotDate', _lastSnapshotDate.toIso8601String());
  }

  Future<void> updateTrackingSnapshotIfNewDay() async {
    final now = DateTime.now();
    final isNewDay = now.difference(_lastSnapshotDate).inDays >= 1;

    if (isNewDay) {
      _prevProductCount = totalProductsLength;
      _prevTotalQuantity = totalStocksQuantity.round();
      _lastSnapshotDate = now;
      await _saveSnapshot();
    }
  }

  double get productCountChangePercent {
    if (_prevProductCount == 0) return 100;
    final diff = totalProductsLength - _prevProductCount;
    return (diff / _prevProductCount) * 100;
  }

  double get quantityChangePercent {
    if (_prevTotalQuantity == 0) return 100;
    final diff = totalStocksQuantity - _prevTotalQuantity;
    return (diff / _prevTotalQuantity) * 100;
  }

  int get totalProductsLength => products.length;
  double get totalStocksQuantity => products.fold(0, (sum, p) => sum + p.totalSacks);
  double get totalStocksKilos => products.fold(0, (sum, p) => sum + p.totalKilos);
  double get totalStocks => totalStocksQuantity + totalStocksKilos;

  Map<String, dynamic> exportProduct(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'costPrice': product.costPrice,
      'retailPrice': product.retailPrice,
      'unit': product.unit,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'category': product.category,
      'lastModified': product.lastModified?.toIso8601String(),
      'batches': product.batches.map((b) => {
        'quantity': b.quantity,
        'kiloQuantity': b.kiloQuantity,
        'date': b.date.toIso8601String(),
      }).toList(),
    };
  }

  void importProduct(Map<String, dynamic> data) {
    final product = Product(
      id: data['id'],
      name: data['name'],
      costPrice: data['costPrice'],
      retailPrice: data['retailPrice'],
      unit: data['unit'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'Uncategorized',
      lastModified: data['lastModified'] != null
          ? DateTime.parse(data['lastModified'])
          : DateTime.now(),
      batches: (data['batches'] as List<dynamic>).map((b) => Batch(
        quantity: b['quantity'],
        kiloQuantity: b['kiloQuantity'] ?? 0,
        date: DateTime.parse(b['date']),
      )).toList(),
    );
    addProduct(product);
  }
}

