import 'package:pocketpos/Model/product_model.dart';
import 'package:pocketpos/Model/product_stock.dart';
import 'package:pocketpos/Model/stock_log.dart';

enum DateFilterType { day, week, month, year, range }

class DashboardMetrics {
  final int totalProducts;
  final int totalVariants;
  final int totalStocks;

  final int totalSoldItems;
  final int totalSoldPerPack;
  final int totalSoldPerPiece;

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
    required this.totalSoldPerPack,
    required this.totalSoldPerPiece,
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

  final List<Product> all = [];

  for (final product in allProducts) {
    all.add(product);
    if (product.hasVariant && product.variants.isNotEmpty) {
      all.addAll(product.variants);
    }
  }

  int totalStocks = 0;
  double unrealizedProfit = 0.0;
  double possibleRevenue = 0.0;
  double totalCost = 0.0;

  // Tally logs by reason
  int totalSold = 0;
  int totalSoldPerPack = 0;
  int totalSoldPerPiece = 0;
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
  double currentCost = 0.0;

  for (final product in all) {
    totalStocks += product.totalQuantity;

    for (final stock in product.stocks) {
      final retail = stock.retailPrice;
      final cost = stock.costPrice;
      final qty = stock.quantity;

      unrealizedProfit += (retail - cost) * qty;
      possibleRevenue += retail * qty;
      totalCost += cost * qty;
    }

    for (final log in product.logs) {
      final inRange = !log.dateLogged.isBefore(startDate) && !log.dateLogged.isAfter(endDate);
      final piecesPerPack = product.piecesPerPack?.toDouble() ?? 1.0;

      final ProductStock? stock = (log.productId.isNotEmpty && product.stocks.any((s) => s.id == log.productId))
          ? product.stocks.firstWhere((s) => s.id == log.productId)
          : (product.stocks.isNotEmpty ? product.stocks.first : null);

      if (stock == null) continue;

      final unitCost = log.isPiece ? stock.costPrice / piecesPerPack : stock.costPrice;
      final unitRetail = log.isPiece ? stock.retailPrice / piecesPerPack : stock.retailPrice;
      final qty = log.quantity;

      switch (log.reason) {
        case StockLogReason.sold:
          final profit = log.profit?.toDouble() ?? 0.0;
          final revenue = unitRetail * qty;
          final cost = unitCost * qty;

          totalSold += qty;
          if (log.isPiece) {
            totalSoldPerPiece += qty;
          } else {
            totalSoldPerPack += qty;
          }

          totalRevenue += revenue;
          realizedProfit += profit;

          if (inRange) {
            currentRevenue += revenue;
            currentProfit += profit;
            currentCost += cost;
          }
          break;

        case StockLogReason.expired:
          totalExpired += qty;
          break;

        case StockLogReason.borrowed:
          totalLoan += qty;
          break;

        case StockLogReason.consumed:
          totalConsumed += qty;
          break;

        case StockLogReason.added:
          totalAdded += qty;
          break;

        case StockLogReason.donated:
          totalDonated += qty;
          break;

        case StockLogReason.damaged:
          totalDamaged += qty;
          break;

        default:
          break;
      }
    }
  }

  return DashboardMetrics(
    totalProducts: allProducts.length,
    totalVariants: all.fold(0, (sum, p) => sum + p.variants.length),
    totalStocks: totalStocks,
    totalSoldItems: totalSold,
    totalSoldPerPack: totalSoldPerPack,
    totalSoldPerPiece: totalSoldPerPiece,
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
