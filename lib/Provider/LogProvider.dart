import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nextpos/core/data/product_store.dart';
import 'package:nextpos/Model/product_model.dart';
import 'package:nextpos/Model/stock_log.dart';

class LogProvider with ChangeNotifier {
  final ProductStore _productBox = ProductStore.instance;
  StreamSubscription<void>? _storeSubscription;

  LogProvider() {
    _storeSubscription = _productBox.watch().listen((_) => notifyListeners());
  }

  List<StockLog> getLogs({
    String? productIdOrName,
    DateTimeRange? dateRange,
  }) {
    final logs = <StockLog>[];

    for (final product in _productBox.values) {
      final matchesProduct = productIdOrName == null ||
          product.id == productIdOrName ||
          product.name.toLowerCase().contains(productIdOrName.toLowerCase());

      if (matchesProduct) logs.addAll(product.logs);

      for (final variant in product.variants) {
        final matchesVariant = productIdOrName == null ||
            variant.id == productIdOrName ||
            variant.name.toLowerCase().contains(productIdOrName.toLowerCase());

        if (matchesVariant) logs.addAll(variant.logs);
      }
    }

    if (dateRange != null) {
      logs.retainWhere((log) {
        final created = log.dateLogged ?? DateTime.now();
        return created.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
            created.isBefore(dateRange.end);
      });
    }

    logs.sort((a, b) => b.dateLogged.compareTo(a.dateLogged));
    return logs;
  }

  List<StockLog> getAllLogsByDateRange(DateTimeRange range) {
    final logs = <StockLog>[];

    for (final product in _productBox.values) {
      logs.addAll(product.logs.where((log) =>
          _inRange(log.dateLogged, range)));

      for (final variant in product.variants) {
        logs.addAll(variant.logs.where((log) =>
            _inRange(log.dateLogged, range)));
      }
    }

    logs.sort((a, b) => b.dateLogged.compareTo(a.dateLogged));
    return logs;
  }

  bool _inRange(DateTime? date, DateTimeRange range) {
    if (date == null) return false;
    return date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(range.end.add(const Duration(seconds: 1)));
  }

  List<StockLog> getLogsChunked({
    String? productIdOrName,
    DateTimeRange? dateRange,
    int offset = 0,
    int limit = 100,
  }) {
    final allLogs = <StockLog>[];

    for (final product in _productBox.values) {
      final matchesProduct = productIdOrName == null ||
          product.id == productIdOrName ||
          product.name.toLowerCase().contains(productIdOrName.toLowerCase());

      if (matchesProduct) allLogs.addAll(product.logs);

      for (final variant in product.variants) {
        final matchesVariant = productIdOrName == null ||
            variant.id == productIdOrName ||
            variant.name.toLowerCase().contains(productIdOrName.toLowerCase());

        if (matchesVariant) allLogs.addAll(variant.logs);
      }
    }

    if (dateRange != null) {
      allLogs.retainWhere((log) => _inRange(log.dateLogged, dateRange));
    }

    // Sort logs newest first
    allLogs.sort((a, b) => b.dateLogged.compareTo(a.dateLogged));

    // Apply pagination (offset + limit)
    final end = (offset + limit) > allLogs.length ? allLogs.length : (offset + limit);
    return allLogs.sublist(offset, end);
  }

  @override
  void dispose() {
    _storeSubscription?.cancel();
    super.dispose();
  }
}
