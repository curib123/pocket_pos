import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/Model/product_model.dart';
import 'package:paninda/Model/batch_model.dart';
import 'package:paninda/View_Model/LoanPersonProvider.dart';

enum DateRangeType { day, week, month, year }

class ProductProvider with ChangeNotifier {
  final Box<Product> _productBox = Hive.box<Product>('products');

  // ─────────────────────────────────────────────
  // 📦 PRODUCT LIST & SEARCH
  // ─────────────────────────────────────────────

  List<Product> get products => _productBox.values.toList();

  bool productExists(String id) => _productBox.containsKey(id);

  Product? getProductById(String id) => _productBox.get(id);

  Product? getProductByName(String name) {
    try {
      return _productBox.values.firstWhere(
            (prod) => prod.name.toLowerCase() == name.toLowerCase(),
      );
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

  // ─────────────────────────────────────────────
  // ➕ CRUD OPERATIONS
  // ─────────────────────────────────────────────

  void addProduct(Product product) {
    if (!productExists(product.id)) {
      _productBox.put(product.id, product);
      notifyListeners();
    }
  }

  void updateProduct(String id, Product updatedProduct) {
    if (productExists(id)) {
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

  // ─────────────────────────────────────────────
  // 📦 BATCH & STOCK MANAGEMENT
  // ─────────────────────────────────────────────

  List<Batch> getBatchesForProduct(String productId) {
    final product = getProductById(productId);
    return product?.batches ?? [];
  }

  void restockProduct(String id, double quantity, {DateTime? date}) {
    final product = getProductById(id);
    if (product != null) {
      product.batches.add(Batch(date: date ?? DateTime.now(), quantity: quantity));
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

    product.batches.removeWhere((b) => b.quantity <= 0);
    product.save();
    notifyListeners();
  }

  void updateProductQuantityManually(String id, double newQuantity) {
    final product = getProductById(id);
    if (product != null) {
      product.batches = [Batch(date: DateTime.now(), quantity: newQuantity)];
      product.save();
      notifyListeners();
    }
  }

  void removeAllBatches(String id) {
    final product = getProductById(id);
    if (product != null) {
      product.batches.clear();
      product.save();
      notifyListeners();
    }
  }

  void removeExpiredBatches(String id, DateTime Function(Batch) getExpiryDate) {
    final product = getProductById(id);
    if (product != null) {
      product.batches.removeWhere((batch) => getExpiryDate(batch).isBefore(DateTime.now()));
      product.save();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // 🛒 CHECKOUT OPERATIONS
  // ─────────────────────────────────────────────
  /// Checkout multiple products in a cart.
  ///
  /// - If [isLoan] is `false`, processes as a regular sale.
  /// - If [isLoan] is `true`, processes as a loan (requires [loanProvider] and [borrowerName]).
  ///
  /// Returns a receipt map or `null` on failure (e.g. stock too low or insufficient cash).
  Map<String, dynamic>? checkoutCart({
    required List<Map<String, dynamic>> cartItems,
    required bool isLoan,
    double buyerCash = 0,
    String borrowerName = '',
    LoanProvider? loanProvider,
  }) {
    double total = 0;
    List<Map<String, dynamic>> receipt = [];

    // Validate all products
    for (var item in cartItems) {
      final productId = item['productId'];
      final quantity = item['quantity'];
      final product = getProductById(productId);

      if (product == null || quantity > product.totalQuantity) return null;

      final itemTotal = quantity * product.retailPrice;
      total += itemTotal;

      receipt.add({
        'productId': product.id,
        'productName': product.name,
        'unit': product.unit,
        'quantity': quantity,
        'unitPrice': product.retailPrice,
        'total': itemTotal,
      });
    }

    // Regular cash checkout
    if (!isLoan) {
      if (buyerCash < total) return null;

      // Deduct stock
      for (var item in cartItems) {
        useStockFIFO(item['productId'], item['quantity']);
      }

      return {
        'items': receipt,
        'grandTotal': total,
        'cashGiven': buyerCash,
        'change': buyerCash - total,
        'timestamp': DateTime.now(),
        'status': 'Paid',
      };
    }

    // Loan checkout
    if (isLoan) {
      if (loanProvider == null || borrowerName.trim().isEmpty) return null;

      for (var item in cartItems) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        final product = getProductById(productId);
        if (product == null) continue;

        useStockFIFO(productId, quantity);

        loanProvider.addLoan(
          LoanPerson(
            name: borrowerName,
            productId: product.id,
            productName: product.name,
            quantity: quantity,
            totalAmount: quantity * product.retailPrice,
            date: DateTime.now(),
            isPaid: false,
          ),
        );
      }

      return {
        'items': receipt,
        'grandTotal': total,
        'timestamp': DateTime.now(),
        'borrower': borrowerName,
        'status': 'Loan',
      };
    }

    return null;
  }

  // ─────────────────────────────────────────────
  // 📊 METRICS & PROFIT
  // ─────────────────────────────────────────────

  double get totalInventoryQuantity =>
      products.fold(0, (sum, p) => sum + p.totalQuantity);

  double get totalInventoryCostValue =>
      products.fold(0, (sum, p) => sum + p.totalCostValue);

  double get totalInventoryRetailValue =>
      products.fold(0, (sum, p) => sum + p.totalRetailValue);

  double get allProductsTotalProfit =>
      products.fold(0, (sum, p) => sum + (p.totalRetailValue - p.totalCostValue));

  int get totalProductCount => _productBox.length;

  int get totalBatchCount => products.fold(0, (sum, p) => sum + p.batches.length);

  bool isStockLow(String id, double threshold) {
    final product = getProductById(id);
    return product != null && product.totalQuantity < threshold;
  }

  List<Map<String, dynamic>> getProfitPerBatch(Product product) {
    return product.batches.map((b) {
      final profit = b.quantity * (product.retailPrice - product.costPrice);
      return {
        'date': b.date,
        'quantity': b.quantity,
        'profit': profit,
      };
    }).toList();
  }

  Map<String, double> getProfitBy(DateRangeType type) {
    final Map<String, double> grouped = {};
    for (final p in products) {
      for (final b in p.batches) {
        final profit = b.quantity * (p.retailPrice - p.costPrice);
        final date = b.date;

        late String key;
        switch (type) {
          case DateRangeType.day:
            key = "${date.year}-${date.month}-${date.day}";
            break;
          case DateRangeType.week:
            key = "${date.year}-W${(date.day / 7).ceil()}";
            break;
          case DateRangeType.month:
            key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
            break;
          case DateRangeType.year:
            key = "${date.year}";
            break;
        }

        grouped[key] = (grouped[key] ?? 0) + profit;
      }
    }
    return grouped;
  }

  /// Calculate total retail, cost, and profit of a cart without processing it
  ///
  /// Returns `null` if any product is missing or quantity exceeds stock
  Map<String, double>? getCartTotalsWithProfit(List<Map<String, dynamic>> cartItems) {
    double totalRetail = 0;
    double totalCost = 0;

    for (var item in cartItems) {
      final productId = item['productId'];
      final quantity = item['quantity'];
      final product = getProductById(productId);

      if (product == null || quantity > product.totalQuantity) return null;

      totalRetail += quantity * product.retailPrice;
      totalCost += quantity * product.costPrice;
    }

    return {
      'totalRetail': totalRetail,
      'totalCost': totalCost,
      'profit': totalRetail - totalCost,
    };
  }


  // ─────────────────────────────────────────────
  // 📤 EXPORT / 📥 IMPORT
  // ─────────────────────────────────────────────




  Map<String, dynamic> exportProduct(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'costPrice': product.costPrice,
      'retailPrice': product.retailPrice,
      'unit': product.unit,
      'description': product.description,
      'imageUrl': product.imageUrl,
      'batches': product.batches
          .map((b) => {
        'quantity': b.quantity,
        'date': b.date.toIso8601String(),
      })
          .toList(),
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
      batches: (data['batches'] as List<dynamic>)
          .map((b) => Batch(
        quantity: b['quantity'],
        date: DateTime.parse(b['date']),
      ))
          .toList(),
    );
    addProduct(product);
  }
}
