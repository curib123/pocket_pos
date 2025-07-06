import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:paninda/Model/loan_person_model.dart';
import 'package:paninda/View/Components/HelperClass/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoanProvider with ChangeNotifier {
  final Box<LoanPerson> _loanBox = Hive.box<LoanPerson>('loans');
  final _secureStorage = const FlutterSecureStorage();
  final _supabaseService = SupabaseService();
  final supabase = Supabase.instance.client;

  DateTime? _lastSyncTime;

  List<LoanPerson> get loans => _loanBox.values.toList();

  /// Load last sync time
  Future<void> loadLastSyncTime() async {
    final stored = await _secureStorage.read(key: 'lastLoanSync');
    if (stored != null) {
      _lastSyncTime = DateTime.tryParse(stored);
    }
  }

  /// Save sync time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _secureStorage.write(key: 'lastLoanSync', value: time.toIso8601String());
    _lastSyncTime = time;
  }

  /// Fetch loans from server
  Future<List<LoanPerson>> getLoansByUserFromDatabase(String userId) async {
    return await _supabaseService.getLoansByUser(userId);
  }

  /// Sync loans with server (2-way sync)
  Future<void> syncLoansWithServer() async {
    try {
      await loadLastSyncTime();

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in.');

      final serverLoans = await getLoansByUserFromDatabase(userId);

      // Merge server → local
      for (var serverLoan in serverLoans) {
        final localLoan = _loanBox.values.firstWhere(
              (loan) =>
          loan.name.toLowerCase() == serverLoan.name.toLowerCase() &&
              loan.productId == serverLoan.productId &&
              loan.isPaid == serverLoan.isPaid,
          orElse: () => LoanPerson(
            name: '',
            productId: '',
            productName: '',
            quantity: 0,
            totalAmount: 0,
            date: DateTime.now(),
            isPaid: false,
          ),
        );

        if (localLoan.name.isEmpty) {
          _loanBox.add(serverLoan);
        } else if (localLoan.lastModified.isBefore(serverLoan.lastModified)) {
          localLoan
            ..quantity = serverLoan.quantity
            ..totalAmount = serverLoan.totalAmount
            ..date = serverLoan.date
            ..isPaid = serverLoan.isPaid
            ..lastModified = serverLoan.lastModified;
          localLoan.save();
        }
      }

      // Upload local changes → server
      final updatedLoans = loans.where((loan) =>
      _lastSyncTime == null || loan.lastModified.isAfter(_lastSyncTime!)).toList();

      if (updatedLoans.isNotEmpty) {
        await _supabaseService.insertLoans(updatedLoans, userId);
      }

      await saveLastSyncTime(DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint('Error during loan sync: $e');
    }
  }

  /// Insert or Update all loans to server
  Future<void> insertOrUpdateLoansToDatabase() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabaseService.insertLoans(loans, userId);
    }
  }

  /// ➕ Add or merge loan
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
      loan
        ..quantity += newLoan.quantity
        ..totalAmount += newLoan.totalAmount
        ..date = DateTime.now()
        ..lastModified = DateTime.now();
      loan.save();
    } else {
      newLoan.lastModified = DateTime.now();
      _loanBox.add(newLoan);
    }

    notifyListeners();
  }

  /// ➖ Deduct loan
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
      loan
        ..quantity -= quantityToDeduct
        ..totalAmount -= amountToDeduct
        ..date = DateTime.now()
        ..lastModified = DateTime.now();

      if (loan.totalAmount <= 0 || loan.quantity <= 0) {
        _loanBox.delete(existingKey);
      } else {
        loan.save();
      }

      notifyListeners();
    }
  }

  /// ✔️ Mark as paid
  void markAsPaid(int index) {
    final loan = _loanBox.getAt(index);
    if (loan != null && !loan.isPaid) {
      loan
        ..isPaid = true
        ..lastModified = DateTime.now();
      loan.save();
      notifyListeners();
    }
  }

  /// ❌ Remove loan
  void removeLoan(String productId) {
    final key = _loanBox.keys.cast<int?>().firstWhere(
          (key) {
        final loan = _loanBox.get(key);
        return loan != null && loan.productId == productId;
      },
      orElse: () => null,
    );

    if (key != null) {
      _loanBox.delete(key);
      notifyListeners();
    }
  }

  /// ✏️ Edit loan
  void editLoanByProductName({
    required String productName,
    required String newName,
    required String newProductName,
    required double newQuantity,
    required double newTotalAmount,
    required DateTime newDate,
  }) {
    final key = _loanBox.keys.cast<int?>().firstWhere(
          (key) {
        final loan = _loanBox.get(key);
        return loan != null && loan.productName.toLowerCase() == productName.toLowerCase();
      },
      orElse: () => null,
    );

    if (key != null) {
      final loan = _loanBox.get(key);
      if (loan != null) {
        loan
          ..name = newName
          ..productName = newProductName
          ..quantity = newQuantity
          ..totalAmount = newTotalAmount
          ..date = newDate
          ..lastModified = DateTime.now();
        loan.save();
        notifyListeners();
      }
    }
  }

  /// 🧹 Clear all
  void clearLoans() {
    _loanBox.clear();
    notifyListeners();
  }

  /// 🔍 Filtered queries
  List<LoanPerson> getLoansByName(String name) {
    return _loanBox.values
        .where((loan) => loan.name.toLowerCase() == name.toLowerCase())
        .toList();
  }

  double get totalLoanAmount =>
      _loanBox.values.where((l) => !l.isPaid).fold(0.0, (sum, l) => sum + l.totalAmount);

  int get totalUnpaidBorrowers => _loanBox.values
      .where((l) => !l.isPaid)
      .map((l) => l.name.toLowerCase())
      .toSet()
      .length;

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

  List<LoanPerson> get unpaidLoans => _loanBox.values.where((l) => !l.isPaid).toList();
  List<LoanPerson> get paidLoans => _loanBox.values.where((l) => l.isPaid).toList();
}
