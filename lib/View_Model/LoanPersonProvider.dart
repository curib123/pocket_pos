import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paninda/Model/loan_person_model.dart';

class LoanProvider with ChangeNotifier {
  final Box<LoanPerson> _loanBox = Hive.box<LoanPerson>('loans');

  // 📄 All loan records
  List<LoanPerson> get loans => _loanBox.values.toList();

  // ➕ Add new loan or merge if same person & product & unpaid
  void addLoan(LoanPerson newLoan) {
    final existingIndex = _loanBox.values.toList().indexWhere((loan) =>
    loan.name.toLowerCase() == newLoan.name.toLowerCase() &&
        loan.productId == newLoan.productId &&
        !loan.isPaid);

    if (existingIndex != -1) {
      final existingLoan = _loanBox.getAt(existingIndex)!;
      existingLoan.quantity += newLoan.quantity;
      existingLoan.totalAmount += newLoan.totalAmount;
      existingLoan.date = DateTime.now();
      existingLoan.save();
    } else {
      _loanBox.add(newLoan);
    }

    notifyListeners();
  }

  // 🔁 Mark loan as paid
  void markAsPaid(int index) {
    final loan = _loanBox.getAt(index);
    if (loan != null && !loan.isPaid) {
      loan.isPaid = true;
      loan.save();
      notifyListeners();
    }
  }

  // ❌ Remove a specific loan
  void removeLoan(int index) {
    _loanBox.deleteAt(index);
    notifyListeners();
  }

  // 🧹 Clear all loan records
  void clearLoans() {
    _loanBox.clear();
    notifyListeners();
  }

  // 🔍 Get all loans for a specific person
  List<LoanPerson> getLoansByName(String name) {
    return _loanBox.values
        .where((loan) => loan.name.toLowerCase() == name.toLowerCase())
        .toList();
  }

  // 📊 Total unpaid loan amount
  double get totalLoanAmount {
    return _loanBox.values
        .where((l) => !l.isPaid)
        .fold(0.0, (sum, l) => sum + l.totalAmount);
  }

  // 📊 Number of unpaid borrowers
  int get totalUnpaidBorrowers {
    return _loanBox.values
        .where((l) => !l.isPaid)
        .map((l) => l.name)
        .toSet()
        .length;
  }

  // 📊 Get total loan value for a given DateTime range
  double getLoanAmountBetween(DateTime start, DateTime end, {bool onlyUnpaid = false}) {
    return _loanBox.values.where((loan) {
      final matchStatus = onlyUnpaid ? !loan.isPaid : true;
      return loan.date.isAfter(start) && loan.date.isBefore(end) && matchStatus;
    }).fold(0.0, (sum, loan) => sum + loan.totalAmount);
  }

  // 📅 Metrics: today, this week, month, year
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

  // ✅ Filter loans by paid/unpaid
  List<LoanPerson> get unpaidLoans =>
      _loanBox.values.where((l) => !l.isPaid).toList();

  List<LoanPerson> get paidLoans =>
      _loanBox.values.where((l) => l.isPaid).toList();
}
