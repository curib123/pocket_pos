import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:retailpos/Model/product_analytics.dart';
import 'package:retailpos/Model/product_model.dart';
import 'package:retailpos/Model/stock_log.dart';

enum DateFilterType { day, week, month, year }

class ProductAnalyticsProvider extends ChangeNotifier {
  final Box<Product> _productBox;
  final Box<ProductAnalytics> _analyticsBox;

  ProductAnalyticsProvider(this._productBox, this._analyticsBox);

  Future<void> refreshAllAnalytics({DateFilterType? filterType}) async {
    for (final product in _productBox.values) {
      if (product.deletedAt != null) continue;
      await _updateAnalytics(product, filterType: filterType);
    }
    _flagTopAndLowPerformers();
  }

  Future<void> _updateAnalytics(Product product, {DateFilterType? filterType}) async {
    final productId = product.id;
    final now = DateTime.now();

    final List<StockLog> logs = product.logs
        .where((log) =>
    log.deletedAt == null &&
        (filterType == null ||
            _isWithinRange(log.dateLogged, now, filterType)))
        .toList();

    final int totalQty = product.stocks.fold(0, (sum, s) => sum + s.quantity);
    final double avgCost = _weightedAverageCost(product);
    final double latestRetail = product.stocks.isNotEmpty ? product.stocks.last.retailPrice : 0.0;
    final int loosePieces = product.looseStock?.remainingPieces ?? 0;

    int soldPacks = 0, soldPieces = 0;
    int expired = 0, damaged = 0, donated = 0, borrowed = 0;
    double totalRevenue = 0.0, totalCost = 0.0;
    int timesSold = 0;

    for (final log in logs) {
      final qty = log.quantity;

      switch (log.reason) {
        case StockLogReason.sold:
          timesSold++;
          if (log.isPiece) {
            soldPieces += qty;
          } else {
            soldPacks += qty;
          }
          totalRevenue += latestRetail * qty;
          totalCost += avgCost * qty;
          break;

        case StockLogReason.expired:
          expired += qty;
          break;

        case StockLogReason.damaged:
          damaged += qty;
          break;

        case StockLogReason.donated:
          donated += qty;
          break;

        case StockLogReason.borrowed:
          borrowed += qty;
          break;

        case StockLogReason.added:
        case StockLogReason.restocked:
        case StockLogReason.adjusted:
        case StockLogReason.deleted:
        case StockLogReason.restored:
        case StockLogReason.cleared:
        // 🔇 These reasons don’t affect analytics totals (for now)
          break;
      }
    }

    final totalUnitsSold = (soldPacks * (product.piecesPerPack ?? 1)) + soldPieces;
    final totalProfit = totalRevenue - totalCost;

    final analytics = ProductAnalytics(
      productId: productId,
      totalQuantity: totalQty,
      loosePieces: loosePieces,
      averageCostPrice: avgCost,
      latestRetailPrice: latestRetail,
      soldPacks: soldPacks,
      soldPieces: soldPieces,
      expired: expired,
      damaged: damaged,
      donated: donated,
      borrowed: borrowed,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      timesSold: timesSold,
      totalUnitsSold: totalUnitsSold,
      isBestSeller: false,
      isLowPerformer: false,
    );

    await _analyticsBox.put(productId, analytics);
    notifyListeners();
  }

  bool _isWithinRange(DateTime date, DateTime now, DateFilterType filter) {
    switch (filter) {
      case DateFilterType.day:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case DateFilterType.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case DateFilterType.month:
        return date.year == now.year && date.month == now.month;
      case DateFilterType.year:
        return date.year == now.year;
    }
  }

  double _weightedAverageCost(Product product) {
    double totalCost = 0.0;
    int totalQty = 0;

    for (var stock in product.stocks) {
      totalCost += stock.costPrice * stock.quantity;
      totalQty += stock.quantity;
    }

    return totalQty > 0 ? totalCost / totalQty : 0.0;
  }

  void _flagTopAndLowPerformers() {
    final all = _analyticsBox.values.toList();
    if (all.isEmpty) return;

    all.sort((a, b) => b.totalUnitsSold.compareTo(a.totalUnitsSold));

    final top5 = all.take(5).map((a) => a.productId).toSet();
    final bottom5 = all.reversed.take(5).map((a) => a.productId).toSet();

    for (var a in all) {
      final updated = a.copyWith(
        isBestSeller: top5.contains(a.productId),
        isLowPerformer: (a.totalUnitsSold == 0 || bottom5.contains(a.productId)),
        lastUpdated: DateTime.now(),
      );
      _analyticsBox.put(a.productId, updated);
    }

    notifyListeners();
  }

  ProductAnalytics? getAnalytics(String productId) => _analyticsBox.get(productId);

  List<ProductAnalytics> get all => _analyticsBox.values.toList();

  List<ProductAnalytics> get bestSellers =>
      _analyticsBox.values.where((a) => a.isBestSeller).toList();

  List<ProductAnalytics> get lowPerformers =>
      _analyticsBox.values.where((a) => a.isLowPerformer).toList();

  Future<void> clearAnalytics() async {
    await _analyticsBox.clear();
    notifyListeners();
  }
}
