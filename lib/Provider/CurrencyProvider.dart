import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_pos_inventory/Helper/Currency.dart';
class CurrencyProvider with ChangeNotifier {
  final List<Map<String, dynamic>> currencies = currencyList;

  late Map<String, dynamic> _selectedCurrency;
  late NumberFormat _currencyFormat;

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
    final box = Hive.box('settings_currency');
    final savedCurrencyName = box.get('currencyName');

    if (savedCurrencyName != null) {
      final savedCurrency = currencies.firstWhere(
            (currency) => currency['name'] == savedCurrencyName,
        orElse: () => currencies[0],
      );
      _selectedCurrency = savedCurrency;
      _currencyFormat = _createFormatter(savedCurrency);
      notifyListeners();
    }
  }

  Future<void> selectCurrency(Map<String, dynamic> currency, {bool save = true}) async {
    _selectedCurrency = currency;
    _currencyFormat = _createFormatter(currency);
    notifyListeners();

    if (save) {
      final box = Hive.box('settings_currency');
      await box.put('currencyName', currency['name']);
    }
  }

  String formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }
}
