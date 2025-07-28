import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/stock_log.dart';

enum DateFilterType { day, week, month, year, range }

class DashboardMetrics {
  final int totalProducts;
  final int totalVariants;
  final int totalStocks;

  final int totalSoldItems;
  final int totalExpiredItems;
  final int totalLoanItems;
  final int totalConsumedItems;
  final int totalAddedItems;
  final int totalDonatedItems;
  final int totalDamageItems;

  final double totalRevenue;
  final double currentRevenue;

  final double realizedProfit;
  final double currentProfit;

  final double unrealizedProfit;
  final double possibleRevenue;

  final double totalCost;
  final double currentCost;

  DashboardMetrics({
    required this.totalProducts,
    required this.totalVariants,
    required this.totalStocks,
    required this.totalSoldItems,
    required this.totalExpiredItems,
    required this.totalLoanItems,
    required this.totalConsumedItems,
    required this.totalAddedItems,
    required this.totalDonatedItems,
    required this.totalDamageItems,
    required this.totalRevenue,
    required this.currentRevenue,
    required this.realizedProfit,
    required this.currentProfit,
    required this.unrealizedProfit,
    required this.possibleRevenue,
    required this.totalCost,
    required this.currentCost,
  });
}

DashboardMetrics generateDashboardMetrics({
  required List<Product> allProducts,
  required DateFilterType filterType,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = now;

  switch (filterType) {
    case DateFilterType.day:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case DateFilterType.week:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      break;
    case DateFilterType.month:
      startDate = DateTime(now.year, now.month, 1);
      break;
    case DateFilterType.year:
      startDate = DateTime(now.year, 1, 1);
      break;
    case DateFilterType.range:
      startDate = customStart ?? now;
      endDate = customEnd ?? now;
      break;
  }

  final all = <Product>[];
  for (final product in allProducts) {
    all.add(product);
    if (product.hasVariant && product.variants.isNotEmpty) {
      all.addAll(product.variants);
    }
  }

  int totalStocks = 0;
  int totalSold = 0;
  int totalExpired = 0;
  int totalLoan = 0;
  int totalConsumed = 0;
  int totalAdded = 0;
  int totalDonated = 0;
  int totalDamaged = 0;

  double totalRevenue = 0.0;
  double currentRevenue = 0.0;

  double realizedProfit = 0.0;
  double currentProfit = 0.0;

  double unrealizedProfit = 0.0;
  double possibleRevenue = 0.0;

  double totalCost = 0.0;
  double currentCost = 0.0;

  for (final p in all) {
    totalStocks += p.totalQuantity;

    for (final stock in p.stocks) {
      unrealizedProfit += (stock.retailPrice - stock.costPrice) * stock.quantity;
      possibleRevenue += stock.retailPrice * stock.quantity;
    }

    for (final log in p.logs) {
      final isInRange = !log.dateLogged.isBefore(startDate) && !log.dateLogged.isAfter(endDate);
      final piecesPerPack = p.piecesPerPack?.toDouble() ?? 1;

      final stock = p.stocks.where((s) => s.id == log.productId).firstOrNull;
      if (stock == null) continue;

      final unitCost = log.isPiece
          ? stock.costPrice / piecesPerPack
          : stock.costPrice;

      final unitRetail = log.isPiece
          ? stock.retailPrice / piecesPerPack
          : stock.retailPrice;

      switch (log.reason) {
        case StockLogReason.sold:
          final logProfit = log.profit?.toDouble() ?? 0;
          final logRevenue = unitRetail * log.quantity;
          final logCost = unitCost * log.quantity;

          totalSold += log.quantity;
          realizedProfit += logProfit;
          totalRevenue += logRevenue;
          totalCost += logCost;

          if (isInRange) {
            currentProfit += logProfit;
            currentRevenue += logRevenue;
            currentCost += logCost;
          }
          break;
        case StockLogReason.expired:
          totalExpired += log.quantity;
          break;
        case StockLogReason.borrowed:
          totalLoan += log.quantity;
          break;
        case StockLogReason.consumed:
          totalConsumed += log.quantity;
          break;
        case StockLogReason.added:
          totalAdded += log.quantity;
          break;
        case StockLogReason.donated:
          totalDonated += log.quantity;
          break;
        case StockLogReason.damaged:
          totalDamaged += log.quantity;
          break;
        default:
          break;
      }
    }
  }

  final totalProducts = allProducts.length;
  final totalVariants = all.fold(0, (sum, p) => sum + p.variants.length);

  return DashboardMetrics(
    totalProducts: totalProducts,
    totalVariants: totalVariants,
    totalStocks: totalStocks,
    totalSoldItems: totalSold,
    totalExpiredItems: totalExpired,
    totalLoanItems: totalLoan,
    totalConsumedItems: totalConsumed,
    totalAddedItems: totalAdded,
    totalDonatedItems: totalDonated,
    totalDamageItems: totalDamaged,
    totalRevenue: totalRevenue,
    currentRevenue: currentRevenue,
    realizedProfit: realizedProfit,
    currentProfit: currentProfit,
    unrealizedProfit: unrealizedProfit,
    possibleRevenue: possibleRevenue,
    totalCost: totalCost,
    currentCost: currentCost,
  );
}
