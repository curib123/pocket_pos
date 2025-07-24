import 'package:hive/hive.dart';

part 'product_analytics.g.dart';

@HiveType(typeId: 5)
class ProductAnalytics extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  int totalQuantity; // 🔢 Total stock quantity across ProductStock

  @HiveField(2)
  int loosePieces; // 🧩 Remaining loose pieces (LooseStock)

  @HiveField(3)
  double averageCostPrice; // 💰 Weighted average cost from ProductStock

  @HiveField(4)
  double latestRetailPrice; // 🏷️ Most recent retail price

  @HiveField(5)
  int soldPacks; // 📦 Total sold by pack (from StockLog)

  @HiveField(6)
  int soldPieces; // 🧨 Total sold by piece

  @HiveField(7)
  int expired; // ☠️ Total expired logs

  @HiveField(8)
  int damaged; // 🛠️ Damaged quantity

  @HiveField(9)
  int donated; // 🎁 Donated quantity

  @HiveField(10)
  int borrowed; // 🤝 Borrowed quantity

  @HiveField(11)
  double totalRevenue; // 💸 Retail * quantity sold

  @HiveField(12)
  double totalCost; // 📉 CostPrice * quantity sold

  @HiveField(13)
  double totalProfit; // 💰 Revenue - Cost

  @HiveField(14)
  int timesSold; // 🧾 How many sale logs (unique sale entries)

  @HiveField(15)
  int totalUnitsSold; // 🧮 soldPacks * piecesPerPack + soldPieces

  @HiveField(16)
  bool isBestSeller; // 👑 Flag set in provider (top 5 best sellers)

  @HiveField(17)
  bool isLowPerformer; // ❄️ Flag set in provider (0 sales or bottom 5)

  @HiveField(18)
  final DateTime lastUpdated; // 🕰️ For syncing & refresh logic

  ProductAnalytics({
    required this.productId,
    required this.totalQuantity,
    required this.loosePieces,
    required this.averageCostPrice,
    required this.latestRetailPrice,
    required this.soldPacks,
    required this.soldPieces,
    required this.expired,
    required this.damaged,
    required this.donated,
    required this.borrowed,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.timesSold,
    required this.totalUnitsSold,
    required this.isBestSeller,
    required this.isLowPerformer,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  ProductAnalytics copyWith({
    String? productId,
    int? totalQuantity,
    int? loosePieces,
    double? averageCostPrice,
    double? latestRetailPrice,
    int? soldPacks,
    int? soldPieces,
    int? expired,
    int? damaged,
    int? donated,
    int? borrowed,
    double? totalRevenue,
    double? totalCost,
    double? totalProfit,
    int? timesSold,
    int? totalUnitsSold,
    bool? isBestSeller,
    bool? isLowPerformer,
    DateTime? lastUpdated,
  }) {
    return ProductAnalytics(
      productId: productId ?? this.productId,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      loosePieces: loosePieces ?? this.loosePieces,
      averageCostPrice: averageCostPrice ?? this.averageCostPrice,
      latestRetailPrice: latestRetailPrice ?? this.latestRetailPrice,
      soldPacks: soldPacks ?? this.soldPacks,
      soldPieces: soldPieces ?? this.soldPieces,
      expired: expired ?? this.expired,
      damaged: damaged ?? this.damaged,
      donated: donated ?? this.donated,
      borrowed: borrowed ?? this.borrowed,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCost: totalCost ?? this.totalCost,
      totalProfit: totalProfit ?? this.totalProfit,
      timesSold: timesSold ?? this.timesSold,
      totalUnitsSold: totalUnitsSold ?? this.totalUnitsSold,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isLowPerformer: isLowPerformer ?? this.isLowPerformer,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory ProductAnalytics.fromMap(Map<String, dynamic> map) {
    return ProductAnalytics(
      productId: map['productId'],
      totalQuantity: map['totalQuantity'],
      loosePieces: map['loosePieces'],
      averageCostPrice: map['averageCostPrice'],
      latestRetailPrice: map['latestRetailPrice'],
      soldPacks: map['soldPacks'],
      soldPieces: map['soldPieces'],
      expired: map['expired'],
      damaged: map['damaged'],
      donated: map['donated'],
      borrowed: map['borrowed'],
      totalRevenue: map['totalRevenue'],
      totalCost: map['totalCost'],
      totalProfit: map['totalProfit'],
      timesSold: map['timesSold'],
      totalUnitsSold: map['totalUnitsSold'],
      isBestSeller: map['isBestSeller'],
      isLowPerformer: map['isLowPerformer'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'totalQuantity': totalQuantity,
      'loosePieces': loosePieces,
      'averageCostPrice': averageCostPrice,
      'latestRetailPrice': latestRetailPrice,
      'soldPacks': soldPacks,
      'soldPieces': soldPieces,
      'expired': expired,
      'damaged': damaged,
      'donated': donated,
      'borrowed': borrowed,
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'totalProfit': totalProfit,
      'timesSold': timesSold,
      'totalUnitsSold': totalUnitsSold,
      'isBestSeller': isBestSeller,
      'isLowPerformer': isLowPerformer,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
