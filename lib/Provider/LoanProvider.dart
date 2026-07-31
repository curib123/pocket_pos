import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nextpos/Helper/Enums/Enum.dart';
import 'package:nextpos/Model/loan_item.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';
import 'package:nextpos/core/data/offline_database.dart';

class LoanProvider with ChangeNotifier {
  final Box<Product> _productBox = Hive.box<Product>('products');
  final _offlineDatabase = OfflineDatabase.instance;

  Future<void> _mirror(Product product) async {
    try {
      await _offlineDatabase.upsertProduct(product);
    } catch (_) {}
  }

  LoanProvider();

  Product? getProductById(String id) {
    for (final product in _productBox.values) {
      if (product.id == id) return product;
      for (final variant in product.variants) {
        if (variant.id == id) return variant;
      }
    }
    return null;
  }

  Map<String, List<LoanItem>> getAllLoansByLoanerName() {
    final result = <String, List<LoanItem>>{};
    for (final product in _productBox.values.where(
      (p) => !p.isDeletedPermanent,
    )) {
      final allLoans = [
        ...product.loans,
        for (final v in product.variants) ...v.loans,
      ];
      for (final loan in allLoans) {
        if (!loan.isReturned && loan.borrowerName.isNotEmpty) {
          result.putIfAbsent(loan.borrowerName, () => []).add(loan);
        }
      }
    }
    return result;
  }

  List<LoanItem> getLoansByBorrower(Product product, String borrowerName) {
    final name = borrowerName.toLowerCase().trim();
    return [
      ...product.loans.where(
        (l) => l.borrowerName.toLowerCase().trim() == name,
      ),
      for (final v in product.variants)
        ...v.loans.where((l) => l.borrowerName.toLowerCase().trim() == name),
    ];
  }

  List<LoanItem> getAllLoans() {
    return [
      for (final product in _productBox.values.where(
        (p) => !p.isDeletedPermanent,
      ))
        ...product.loans,
      for (final product in _productBox.values.where(
        (p) => !p.isDeletedPermanent,
      ))
        for (final variant in product.variants) ...variant.loans,
    ];
  }

  double getTotalLoanAmountForBorrower(String borrowerName) {
    final name = borrowerName.toLowerCase().trim();
    double total = 0;
    for (final product in _productBox.values.where(
      (p) => !p.isDeletedPermanent,
    )) {
      final allLoans = [
        ...product.loans,
        for (final v in product.variants) ...v.loans,
      ];
      for (final loan in allLoans) {
        if (loan.borrowerName.toLowerCase().trim() == name) {
          total += loan.amount - loan.paid;
        }
      }
    }
    return total;
  }

  List<String> getAllLoanerNames() {
    final Set<String> names = {};
    for (final product in _productBox.values.where(
      (p) => !p.isDeletedPermanent,
    )) {
      final allLoans = [
        ...product.loans,
        for (final v in product.variants) ...v.loans,
      ];
      for (final loan in allLoans) {
        if (loan.borrowerName.isNotEmpty) names.add(loan.borrowerName.trim());
      }
    }
    return names.toList()..sort();
  }

  Future<void> payLoanForProduct({
    required String productId,
    required String borrowerName,
    required double amount,
    bool track = false,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    final updatedLoans = <LoanItem>[];
    final logs = <StockLog>[];
    double remaining = amount;

    for (final loan in product.loans) {
      if (loan.borrowerName.toLowerCase().trim() !=
          borrowerName.toLowerCase().trim()) {
        updatedLoans.add(loan);
        continue;
      }

      final unpaid = loan.amount - loan.paid;
      final payment = remaining >= unpaid ? unpaid : remaining;
      loan.paid += payment;
      remaining -= payment;

      if (track && payment > 0) {
        logs.add(
          StockLog(
            id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
            productId: product.id,
            quantity: (payment / loan.price).floor(),
            isPiece: true,
            profit: loan.price * (payment / loan.price),
            reason: StockLogReason.sold,
            remarks: 'Paid loan of ${loan.name} by $borrowerName',
          ),
        );
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

    final key = _productBox.keys.firstWhere(
      (k) => _productBox.get(k)?.id == productId,
    );
    await _productBox.put(key, updatedProduct);
    await _mirror(updatedProduct);
    notifyListeners();
  }

  Future<void> payAllLoansByBorrower(
    String borrowerName,
    double amount, {
    bool track = false,
  }) async {
    double remaining = amount;

    for (final key in _productBox.keys) {
      final product = _productBox.get(key);
      if (product == null) continue;

      final loans =
          [...product.loans]
              .where(
                (loan) =>
                    loan.borrowerName.toLowerCase().trim() ==
                    borrowerName.toLowerCase().trim(),
              )
              .toList()
            ..sort((a, b) => a.loanDate.compareTo(b.loanDate));

      final updatedLoans = <LoanItem>[];
      final logs = <StockLog>[];

      for (final loan in loans) {
        if (remaining <= 0) break;

        final unpaid = loan.amount - loan.paid;
        final payment = remaining >= unpaid ? unpaid : remaining;
        loan.paid += payment;
        remaining -= payment;

        if (track && payment > 0) {
          logs.add(
            StockLog(
              id: 'log-${DateTime.now().millisecondsSinceEpoch}-${product.id}',
              productId: product.id,
              quantity: (payment / loan.price).floor(),
              isPiece: true,
              profit: loan.price * (payment / loan.price),
              reason: StockLogReason.sold,
              remarks: 'Paid loan of ${loan.name} by $borrowerName',
            ),
          );
        }

        if (loan.paid >= loan.amount) {
          loan.isReturned = true;
          loan.returnDate = DateTime.now();
        }

        if (loan.paid < loan.amount) {
          updatedLoans.add(loan);
        }
      }

      final unrelatedLoans = product.loans
          .where(
            (l) =>
                l.borrowerName.toLowerCase().trim() !=
                borrowerName.toLowerCase().trim(),
          )
          .toList();
      final allLoans = [...unrelatedLoans, ...updatedLoans];

      final updatedProduct = product.copyWith(
        loans: allLoans,
        logs: [...product.logs, ...logs],
        lastModified: DateTime.now(),
      );

      await _productBox.put(key, updatedProduct);
      await _mirror(updatedProduct);
      if (remaining <= 0) break;
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

    final loanAmountPerBorrower = <String, double>{};
    final loanCountPerProduct = <String, int>{};
    final loanAmountPerProduct = <String, double>{};

    final now = targetDate ?? DateTime.now();

    bool isWithinFilter(DateTime date) {
      switch (filter) {
        case LoanFilterType.day:
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
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

    for (final product in _productBox.values.where(
      (p) => !p.isDeletedPermanent,
    )) {
      for (final loan in product.loans) {
        if (!isWithinFilter(loan.loanDate)) continue;

        totalLoanCount++;
        totalLoanQty += loan.quantity;
        final loanTotal = loan.quantity * loan.price;
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
    required DateTime loanDate,
    int? newQuantity,
    double? newPrice,
    String? newBorrowerName,
    bool track = false,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    final updatedLoans = <LoanItem>[];
    bool loanEdited = false;

    for (final loan in product.loans) {
      final isMatch =
          loan.borrowerName.toLowerCase().trim() ==
              borrowerName.toLowerCase().trim() &&
          loan.loanDate == loanDate;

      if (isMatch && !loanEdited) {
        updatedLoans.add(
          loan.copyWith(
            quantity: newQuantity ?? loan.quantity,
            price: newPrice ?? loan.price,
            borrowerName: newBorrowerName ?? loan.borrowerName,
          ),
        );
        loanEdited = true;
        if (track)
          debugPrint(
            '📝 Edited loan for $borrowerName on ${loanDate.toIso8601String()}',
          );
      } else {
        updatedLoans.add(loan);
      }
    }

    if (!loanEdited) {
      debugPrint(
        '⚠️ No matching loan found to edit for $borrowerName on $loanDate',
      );
      return;
    }

    final updatedProduct = product.copyWith(
      loans: updatedLoans,
      lastModified: DateTime.now(),
    );
    final key = _productBox.keys.firstWhere(
      (k) => _productBox.get(k)?.id == productId,
    );
    await _productBox.put(key, updatedProduct);
    await _mirror(updatedProduct);

    notifyListeners();
  }
}
