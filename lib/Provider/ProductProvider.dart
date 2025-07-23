import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pocketpos/Helper/Enums/enum.dart';
import 'package:pocketpos/Model/loan_item.dart';
import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/stock_log.dart';

class ProductProvider extends ChangeNotifier {
  final Box<Product> _productBox;

  List<Product> _products = [];
  List<Product> get products => _products;

  ProductProvider(this._productBox) {
    initializeProducts();
  }

  Future<void> initializeProducts() async {
    if (_productBox.isEmpty) {
      print("📦 Hive is empty.");
    } else {
      print("📦 Loading products from Hive.");
      refreshProducts();
    }
  }

  void refreshProducts({bool silently = false}) {
    _products = _productBox.values
        .where((p) => p.deletedAt == null)
        .toList()
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));

    if (!silently) {
    }

    notifyListeners();
  }

  bool barcodeExists(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return true;
      for (final variant in product.variants) {
        if (variant.barcode == barcode) return true;
      }
    }
    return false;
  }

  Map<String, List<LoanItem>> getAllLoansByLoanerName() {
    final Map<String, List<LoanItem>> result = {};

    for (final product in _products) {
      for (final loan in product.loans) {
        if (!loan.isReturned && loan.borrowerName.isNotEmpty) {
          result.putIfAbsent(loan.borrowerName, () => []);
          result[loan.borrowerName]!.add(loan);
        }
      }

      for (final variant in product.variants) {
        for (final loan in variant.loans) {
          if (!loan.isReturned && loan.borrowerName.isNotEmpty) {
            result.putIfAbsent(loan.borrowerName, () => []);
            result[loan.borrowerName]!.add(loan);
          }
        }
      }
    }

    return result;
  }

  List<LoanItem> getLoansByBorrower(Product product, String borrowerName) {
    final List<LoanItem> result = [];

    final normalizedName = borrowerName.toLowerCase().trim();

    // Main product loans
    for (final loan in product.loans) {
      if (loan.borrowerName.toLowerCase().trim() == normalizedName) {
        result.add(loan);
      }
    }

    // Variant product loans
    for (final variant in product.variants) {
      for (final loan in variant.loans) {
        if (loan.borrowerName.toLowerCase().trim() == normalizedName) {
          result.add(loan);
        }
      }
    }

    return result;
  }


  List<LoanItem> getAllLoans() {
    final List<LoanItem> result = [];

    for (final product in _products) {
      // Add main product loans
      for (final loan in product.loans) {
        result.add(loan);
      }

      // Add variant product loans
      for (final variant in product.variants) {
        for (final loan in variant.loans) {
          result.add(loan);
        }
      }
    }

    return result;
  }

  double getTotalLoanAmountForBorrower(String borrowerName) {
    double total = 0;

    for (final product in _products) {
      for (final loan in product.loans) {
        if (loan.borrowerName.trim().toLowerCase() == borrowerName.trim().toLowerCase()) {
          total += loan.amount - loan.paid;
        }
      }

      for (final variant in product.variants) {
        for (final loan in variant.loans) {
          if (loan.borrowerName.trim().toLowerCase() == borrowerName.trim().toLowerCase()) {
            total += loan.amount - loan.paid;
          }
        }
      }
    }

    return total;
  }

  List<String> getAllLoanerNames() {
    final Set<String> names = {};

    for (final product in _products) {
      for (final loan in product.loans) {
        if (loan.borrowerName.isNotEmpty == true) {
          names.add(loan.borrowerName.trim());
        }
      }

      for (final variant in product.variants) {
        for (final loan in variant.loans) {
          if (loan.borrowerName.isNotEmpty == true) {
            names.add(loan.borrowerName.trim());
          }
        }
      }
    }

    return names.toList()..sort(); // optional: sort alphabetically
  }

  Future<void> payLoanForProduct({
    required String productId,
    required String borrowerName,
    required double amount,
    bool track = false,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    final List<LoanItem> updatedLoans = [];
    final List<StockLog> logs = [];
    double remainingAmount = amount;

    for (final loan in product.loans) {
      if (loan.borrowerName.toLowerCase().trim() != borrowerName.toLowerCase().trim()) {
        updatedLoans.add(loan);
        continue;
      }

      final unpaid = loan.amount - loan.paid;
      final payment = remainingAmount >= unpaid ? unpaid : remainingAmount;
      loan.paid += payment;
      remainingAmount -= payment;

      if (track && payment > 0) {
        logs.add(StockLog(
          id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
          productId: product.id,
          quantity: (payment / loan.price).floor(),
          isPiece: true,
          profit: loan.price * (payment / loan.price), // Adjust as needed
          reason: StockLogReason.sold,
          remarks: 'Paid loan of ${loan.name} by $borrowerName',
        ));
      }

      if (loan.paid >= loan.amount) {
        loan.isReturned = true;
        loan.returnDate = DateTime.now();
      }

      if (loan.paid < loan.amount) {
        updatedLoans.add(loan);
      }
    }

    final updatedProduct = product.copyWith(
      loans: updatedLoans,
      logs: [...product.logs, ...logs],
      lastModified: DateTime.now(),
    );

    await _productBox.put(product.key, updatedProduct);
    _products[_products.indexWhere((p) => p.id == productId)] = updatedProduct;
    notifyListeners();
  }

  Future<void> payAllLoansByBorrower(String borrowerName, double amount, {bool track = false}) async {
    double remainingAmount = amount;

    for (final product in _products) {
      final List<LoanItem> updatedLoans = [];
      final List<StockLog> logs = [];

      for (final loan in product.loans) {
        if (loan.borrowerName.toLowerCase().trim() != borrowerName.toLowerCase().trim()) {
          updatedLoans.add(loan);
          continue;
        }

        final unpaid = loan.amount - loan.paid;
        final payment = remainingAmount >= unpaid ? unpaid : remainingAmount;
        loan.paid += payment;
        remainingAmount -= payment;

        if (track && payment > 0) {
          logs.add(StockLog(
            id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
            productId: product.id,
            quantity: (payment / loan.price).floor(),
            isPiece: true,
            profit: loan.price * (payment / loan.price),
            reason: StockLogReason.sold,
            remarks: 'Paid loan of ${loan.name} by $borrowerName',
          ));
        }

        if (loan.paid >= loan.amount) {
          loan.isReturned = true;
          loan.returnDate = DateTime.now();
        }

        if (loan.paid < loan.amount) {
          updatedLoans.add(loan);
        }

        if (remainingAmount <= 0) break;
      }

      final updatedProduct = product.copyWith(
        loans: updatedLoans,
        logs: [...product.logs, ...logs],
        lastModified: DateTime.now(),
      );

      await _productBox.put(product.key, updatedProduct);
      _products[_products.indexWhere((p) => p.id == product.id)] = updatedProduct;

      if (remainingAmount <= 0) break;
    }

    notifyListeners();
  }

  Map<String, dynamic> generateLoanMetrics({
    LoanFilterType filter = LoanFilterType.all,
    DateTime? targetDate,
  }) {
    int totalLoanCount = 0;
    int totalLoanQty = 0;
    double totalLoanAmount = 0;

    final Map<String, double> loanAmountPerBorrower = {};
    final Map<String, int> loanCountPerProduct = {};
    final Map<String, double> loanAmountPerProduct = {};

    final now = targetDate ?? DateTime.now();

    bool isWithinFilter(DateTime date) {
      switch (filter) {
        case LoanFilterType.day:
          return date.year == now.year && date.month == now.month && date.day == now.day;
        case LoanFilterType.week:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          return date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              date.isBefore(weekEnd.add(const Duration(days: 1)));
        case LoanFilterType.month:
          return date.year == now.year && date.month == now.month;
        case LoanFilterType.year:
          return date.year == now.year;
        case LoanFilterType.all:
        default:
          return true;
      }
    }

    for (final product in _products) {
      for (final loan in product.loans) {
        if (!isWithinFilter(loan.loanDate)) continue;

        totalLoanCount++;
        totalLoanQty += loan.quantity;
        final double loanTotal = loan.quantity * loan.price;
        totalLoanAmount += loanTotal;

        final borrower = loan.borrowerName.toLowerCase().trim();
        loanAmountPerBorrower[borrower] =
            (loanAmountPerBorrower[borrower] ?? 0) + loanTotal;

        loanCountPerProduct[product.name] =
            (loanCountPerProduct[product.name] ?? 0) + 1;
        loanAmountPerProduct[product.name] =
            (loanAmountPerProduct[product.name] ?? 0) + loanTotal;
      }
    }

    return {
      'totalLoanCount': totalLoanCount,
      'totalLoanQuantity': totalLoanQty,
      'totalLoanAmount': totalLoanAmount,
      'loanAmountPerBorrower': loanAmountPerBorrower,
      'loanCountPerProduct': loanCountPerProduct,
      'loanAmountPerProduct': loanAmountPerProduct,
    };
  }

  Future<void> editLoanForProduct({
    required String productId,
    required String borrowerName,
    required DateTime loanDate, // Identifier for the specific loan
    int? newQuantity,
    double? newPrice,
    String? newBorrowerName,
    bool track = false,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    final List<LoanItem> updatedLoans = [];
    bool loanEdited = false;

    for (final loan in product.loans) {
      final isMatch = loan.borrowerName.toLowerCase().trim() == borrowerName.toLowerCase().trim() &&
          loan.loanDate == loanDate;

      if (isMatch && !loanEdited) {
        final updatedLoan = loan.copyWith(
          quantity: newQuantity ?? loan.quantity,
          price: newPrice ?? loan.price,
          borrowerName: newBorrowerName ?? loan.borrowerName,
        );

        updatedLoans.add(updatedLoan);
        loanEdited = true;

        if (track) {
          print('📝 Edited loan for $borrowerName on ${loanDate.toIso8601String()}');
          // Optional: Add log entry to logs
        }
      } else {
        updatedLoans.add(loan);
      }
    }

    if (!loanEdited) {
      print('⚠️ No matching loan found to edit for $borrowerName on $loanDate');
      return;
    }

    final updatedProduct = product.copyWith(loans: updatedLoans, lastModified: DateTime.now());
    await _productBox.put(product.key, updatedProduct);
    _products[_products.indexWhere((p) => p.id == productId)] = updatedProduct;

    notifyListeners();
  }

  Product? getProductOrVariantByBarcode(String barcode) {
    for (final product in _products) {
      if (product.barcode == barcode) return product;

      for (final variant in product.variants) {
        if (variant.barcode == barcode) return variant;
      }
    }
    return null;
  }


  List<Product> getProductsByCategory(String category) =>
      _products.where((product) => product.category == category).toList();

  Product? getProductById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
      for (final variant in product.variants) {
        if (variant.id == id) return variant;
      }
    }
    return null;
  }

  List<Product> getAllProductsWithVariants() {
    final List<Product> all = [];
    for (final product in _products) {
      all.add(product);
      all.addAll(product.variants);
    }
    return all;
  }

  List<Product> getAllProductsWithVariantsByCategory(String category) {
    final List<Product> all = [];
    for (final product in _products) {
      if (product.category == category) all.add(product);
      for (final variant in product.variants) {
        if (variant.category == category) all.add(variant);
      }
    }
    return all;
  }

  Product? getProductByName(String name) {
    try {
      return _products.firstWhere(
            (p) => p.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<Product> search(String keyword) => _products
      .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
      .toList();

  List<Map<String, dynamic>> exportToJsonList() =>
      _products.map((p) => p.toMap()).toList();

  Future<void> upsertProduct(Product product) async {
    try {
      final existingIndex = _products.indexWhere((p) => p.id == product.id);
      final bool isNew = existingIndex == -1;

      if (isNew) {
        final nameExists = _products.any((p) =>
        p.name.trim().toLowerCase() == product.name.trim().toLowerCase() &&
            p.deletedAt == null);

        if (nameExists) {
          return;
        }

        final List<StockLog> logs = [];

        for (final stock in product.stocks) {
          if (stock.quantity > 0) {
            logs.add(StockLog(
              id: 'log-${stock.id}',
              productId: product.id,
              quantity: stock.quantity,
              isPiece: false,
              reason: StockLogReason.added,
              remarks: 'Initial stock (pack)',
            ));
          }
        }

        final loose = product.looseStock;
        if (loose != null && loose.remainingPieces > 0) {
          logs.add(StockLog(
            id: 'log-${product.id}-loose',
            productId: product.id,
            quantity: loose.remainingPieces,
            isPiece: true,
            reason: StockLogReason.added,
            remarks: 'Initial stock (loose)',
          ));
        }

        final newProduct = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, ...logs],
          looseStock: product.looseStock, // 👈 ensures looseStock is persisted
        );

        await _productBox.put(newProduct.id, newProduct);
        refreshProducts();
      } else {
        // 🧠 Get current product from box for comparison
        final currentProduct = _productBox.get(product.id);

        final List<StockLog> logs = [
          StockLog(
            id: 'log-${product.id}-adjust-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            quantity: 0,
            isPiece: false,
            reason: StockLogReason.adjusted,
            remarks: 'Product details manually updated',
          )
        ];

        // 🧮 Optional: log loose stock change if it changed
        final looseBefore = currentProduct?.looseStock?.remainingPieces ?? 0;
        final looseAfter = product.looseStock?.remainingPieces ?? 0;

        if (looseBefore != looseAfter) {
          final diff = looseAfter - looseBefore;
          logs.add(StockLog(
            id: 'log-${product.id}-loose-adjust-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            quantity: diff.abs(),
            isPiece: true,
            reason: StockLogReason.adjusted,
            remarks: diff > 0 ? 'Added loose stock' : 'Removed loose stock',
          ));
        }

        final updatedProduct = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, ...logs],
          looseStock: product.looseStock, // 👈 update looseStock on edit
        );

        await _productBox.put(updatedProduct.id, updatedProduct);
        refreshProducts();
      }
    } catch (e) {
      print("⚠️ Error in upsertProduct: $e");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null) {
        final log = StockLog(
          id: 'log-${id}-deleted',
          productId: id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.deleted,
          remarks: 'Product was deleted',
        );

        final deleted = product.copyWith(
          deletedAt: DateTime.now(),
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(id, deleted);
        refreshProducts();
      }
    } catch (e) {
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      final product = _productBox.get(id);
      if (product != null && product.deletedAt != null) {
        final log = StockLog(
          id: 'log-${id}-restored',
          productId: id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.restored,
          remarks: 'Product was restored',
        );

        final restored = product.copyWith(
          deletedAt: null,
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(id, restored);
        refreshProducts();
      }
    } catch (e) {
    }
  }

  Future<void> clearAll() async {
    try {
      for (final product in _products) {
        final log = StockLog(
          id: 'log-${product.id}-cleared',
          productId: product.id,
          quantity: 0,
          isPiece: false,
          reason: StockLogReason.cleared,
          remarks: 'Cleared from system',
        );

        final cleared = product.copyWith(
          lastModified: DateTime.now(),
          logs: [...product.logs, log],
        );

        await _productBox.put(cleared.id, cleared);
      }

      await _productBox.clear();
      refreshProducts();
    } catch (e) {
    }
  }
}
