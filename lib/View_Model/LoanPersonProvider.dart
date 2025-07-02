import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paninda/Model/loan_person_model.dart';

class LoanProvider with ChangeNotifier {
  final Box<LoanPerson> _loanBox = Hive.box<LoanPerson>('loans');

  List<LoanPerson> get loans => _loanBox.values.toList();

  /// ➕ Add new loan or merge if same name, productId, and unpaid
  void addLoan(LoanPerson newLoan) {
    final existingKey = _loanBox.keys.cast<int?>().firstWhere(
          (key) {
        final loan = _loanBox.get(key);
        return loan != null &&
            loan.name.toLowerCase() == newLoan.name.toLowerCase() &&
            loan.productId == newLoan.productId &&
            !loan.isPaid;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      final loan = _loanBox.get(existingKey)!;
      loan.quantity += newLoan.quantity;
      loan.totalAmount += newLoan.totalAmount;
      loan.date = DateTime.now();
      loan.save();
    } else {
      _loanBox.add(newLoan);
    }

    notifyListeners();
  }

  /// ➖ Deduct specific loan by person & product
  void deductLoan({
    required String name,
    required String productId,
    int quantityToDeduct = 0,
    required double amountToDeduct,
  }) {
    final existingKey = _loanBox.keys.cast<int?>().firstWhere(
          (key) {
        final loan = _loanBox.get(key);
        return loan != null &&
            loan.name.toLowerCase() == name.toLowerCase() &&
            loan.productId == productId &&
            !loan.isPaid;
      },
      orElse: () => null,
    );

    if (existingKey != null) {
      final loan = _loanBox.get(existingKey)!;
      loan.quantity -= quantityToDeduct;
      loan.totalAmount -= amountToDeduct;
      loan.date = DateTime.now();

      if (loan.totalAmount <= 0 || loan.quantity <= 0) {
        _loanBox.delete(existingKey);
      } else {
        loan.save();
      }

      notifyListeners();
    }
  }

  void markAsPaid(int index) {
    final loan = _loanBox.getAt(index);
    if (loan != null && !loan.isPaid) {
      loan.isPaid = true;
      loan.save();
      notifyListeners();
    }
  }

  void removeLoan(int index) {
    _loanBox.deleteAt(index);
    notifyListeners();
  }

  void clearLoans() {
    _loanBox.clear();
    notifyListeners();
  }

  /// 🔍 Get all loans (paid/unpaid) by name
  List<LoanPerson> getLoansByName(String name) {
    return _loanBox.values
        .where((loan) => loan.name.toLowerCase() == name.toLowerCase())
        .toList();
  }

  /// 📊 Total unpaid loan amount
  double get totalLoanAmount {
    return _loanBox.values
        .where((l) => !l.isPaid)
        .fold(0.0, (sum, l) => sum + l.totalAmount);
  }

  /// 📊 Count of unique unpaid borrowers
  int get totalUnpaidBorrowers {
    return _loanBox.values
        .where((l) => !l.isPaid)
        .map((l) => l.name.toLowerCase())
        .toSet()
        .length;
  }

  /// 📊 Loan amounts in custom date ranges
  double getLoanAmountBetween(DateTime start, DateTime end, {bool onlyUnpaid = false}) {
    return _loanBox.values
        .where((loan) {
      final isInDate = loan.date.isAfter(start) && loan.date.isBefore(end);
      final matchesStatus = onlyUnpaid ? !loan.isPaid : true;
      return isInDate && matchesStatus;
    })
        .fold(0.0, (sum, loan) => sum + loan.totalAmount);
  }

  double get todayLoanAmount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getLoanAmountBetween(start, end);
  }

  double get thisWeekLoanAmount {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return getLoanAmountBetween(start, end);
  }

  double get thisMonthLoanAmount {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    return getLoanAmountBetween(start, end);
  }

  double get thisYearLoanAmount {
    final now = DateTime.now();
    final start = DateTime(now.year);
    final end = DateTime(now.year + 1);
    return getLoanAmountBetween(start, end);
  }

  /// 🧾 Filtered loans
  List<LoanPerson> get unpaidLoans =>
      _loanBox.values.where((l) => !l.isPaid).toList();

  List<LoanPerson> get paidLoans =>
      _loanBox.values.where((l) => l.isPaid).toList();
}
