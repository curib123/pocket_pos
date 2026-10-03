import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextpos/Helper/Classes_Methods/Currency.dart';
import 'package:nextpos/core/data/offline_database.dart';

class CurrencyProvider with ChangeNotifier {
  final List<Map<String, dynamic>> currencies = currencyList;

  late Map<String, dynamic> _selectedCurrency;
  late NumberFormat _currencyFormat;
  final _database = OfflineDatabase.instance;
  bool _disposed = false;

  CurrencyProvider() {
    // Initialize with fallback currency synchronously
    _selectedCurrency = currencies[0];
    _currencyFormat = _createFormatter(_selectedCurrency);

    // Then load saved currency asynchronously
    loadCurrency();
  }

  Map<String, dynamic> get selectedCurrency => _selectedCurrency;
  NumberFormat get currencyFormat => _currencyFormat;

  NumberFormat _createFormatter(Map<String, dynamic> currency) {
    return NumberFormat.currency(
      locale: currency['locale'],
      symbol: currency['symbol'],
      decimalDigits: currency['decimalDigits'],
    );
  }

  Future<void> loadCurrency() async {
    final savedCurrencyName = await _database.getMetadata('currencyName');

    if (savedCurrencyName != null) {
      final savedCurrency = currencies.firstWhere(
        (currency) => currency['name'] == savedCurrencyName,
        orElse: () => currencies[0],
      );
      _selectedCurrency = savedCurrency;
      _currencyFormat = _createFormatter(savedCurrency);
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> selectCurrency(
    Map<String, dynamic> currency, {
    bool save = true,
  }) async {
    _selectedCurrency = currency;
    _currencyFormat = _createFormatter(currency);
    if (!_disposed) notifyListeners();

    if (save) {
      await _database.setMetadata('currencyName', currency['name'] as String);
    }
  }

  String formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

