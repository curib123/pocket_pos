import 'product_stock.dart';
import 'loose_stock.dart';
import 'stock_log.dart';
import 'loan_item.dart';

class Product {
  final String id;
  final String name;
  final String? category;
  final bool isSoldByPack;
  final bool isSoldByPiece;
  final int? piecesPerPack;
  final String? unit;
  final String? imagePath;
  final double costPrice;
  final double sellingPrice;
  final String? supplierName;
  final int reorderLevel;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isSoftDeleted;
  final List<ProductStock> stocks;
  final LooseStock? looseStock;
  final List<StockLog> logs;
  final bool hasVariant;
  final List<Product> variants;
  final bool isVariant;
  final String? barcode;
  final List<LoanItem> loans;
  final bool isDeletedPermanent;

  int get totalQuantity => stocks.fold(0, (sum, stock) => sum + stock.quantity);

  int get totalQuantityByPieces => totalQuantity * (piecesPerPack ?? 1);

  bool get isOutOfStock => totalQuantity == 0;

  bool get isLowStock =>
      totalQuantity > 0 && totalQuantity <= reorderLevel;

  List<StockLog> getLogsByReason(StockLogReason reason) =>
      logs.where((log) => log.reason == reason).toList();

  Map<StockLogReason, List<StockLog>> get logsByReason {
    final Map<StockLogReason, List<StockLog>> grouped = {};
    for (final log in logs) {
      grouped.putIfAbsent(log.reason, () => []).add(log);
    }
    return grouped;
  }

  Map<StockLogReason, int> get logCountsByReason {
    final Map<StockLogReason, int> counts = {};
    for (final log in logs) {
      counts[log.reason] = (counts[log.reason] ?? 0) + 1;
    }
    return counts;
  }

  List<StockLog> get allLogs => logs;

  Product({
    required this.id,
    required this.name,
    required this.isSoldByPack,
    required this.isSoldByPiece,
    this.piecesPerPack,
    this.category,
    this.unit,
    this.imagePath,
    this.costPrice = 0,
    this.sellingPrice = 0,
    this.supplierName,
    this.reorderLevel = 5,
    this.barcode,
    required this.createdAt,
    required this.lastModified,
    this.isSoftDeleted = false,
    this.stocks = const [],
    this.looseStock,
    this.logs = const [],
    this.hasVariant = false,
    this.variants = const [],
    this.isVariant = false,
    this.loans = const [],
    this.isDeletedPermanent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'isSoldByPack': isSoldByPack,
      'isSoldByPiece': isSoldByPiece,
      'piecesPerPack': piecesPerPack,
      'unit': unit,
      'imagePath': imagePath,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'supplierName': supplierName,
      'reorderLevel': reorderLevel,
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isSoftDeleted': isSoftDeleted,
      'stocks': stocks.map((s) => s.toMap()).toList(),
      'looseStock': looseStock?.toMap(),
      'logs': logs.map((l) => l.toMap()).toList(),
      'hasVariant': hasVariant,
      'variants': variants.map((v) => v.toMap()).toList(),
      'isVariant': isVariant,
      'loans': loans.map((l) => l.toMap()).toList(),
      'isDeletedPermanent': isDeletedPermanent,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final reorderLevel =
        int.tryParse(map['reorderLevel']?.toString() ?? '') ?? 5;

    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isSoldByPack: map['isSoldByPack'],
      isSoldByPiece: map['isSoldByPiece'],
      piecesPerPack: map['piecesPerPack'],
      unit: map['unit'],
      imagePath: map['imagePath'],
      costPrice: double.tryParse(map['costPrice']?.toString() ?? '') ?? 0,
      sellingPrice:
          double.tryParse(map['sellingPrice']?.toString() ?? '') ?? 0,
      supplierName: map['supplierName']?.toString(),
      reorderLevel: reorderLevel < 0 ? 0 : reorderLevel,
      barcode: map['barcode'],
      createdAt: DateTime.parse(map['createdAt']),
      lastModified: DateTime.parse(map['lastModified']),
      isSoftDeleted: map['isSoftDeleted'] ?? false,
      stocks: (map['stocks'] as List?)
              ?.map((s) => ProductStock.fromMap(s))
              .toList() ??
          [],
      looseStock: map['looseStock'] != null
          ? LooseStock.fromMap(map['looseStock'])
          : null,
      logs: (map['logs'] as List?)
              ?.map((l) => StockLog.fromMap(l))
              .toList() ??
          [],
      hasVariant: map['hasVariant'] ?? false,
      variants: (map['variants'] as List?)
              ?.map((v) => Product.fromMap(v))
              .toList() ??
          [],
      isVariant: map['isVariant'] ?? false,
      loans: (map['loans'] as List?)
              ?.map((l) => LoanItem.fromMap(l))
              .toList() ??
          [],
      isDeletedPermanent: map['isDeletedPermanent'] ?? false,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSoldByPack,
    bool? isSoldByPiece,
    int? piecesPerPack,
    String? unit,
    String? imagePath,
    double? costPrice,
    double? sellingPrice,
    String? supplierName,
    int? reorderLevel,
    String? barcode,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isSoftDeleted,
    List<ProductStock>? stocks,
    LooseStock? looseStock,
    List<StockLog>? logs,
    List<Product>? variants,
    bool? hasVariant,
    bool? isVariant,
    List<LoanItem>? loans,
    bool? isDeletedPermanent,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSoldByPack: isSoldByPack ?? this.isSoldByPack,
      isSoldByPiece: isSoldByPiece ?? this.isSoldByPiece,
      piecesPerPack: piecesPerPack ?? this.piecesPerPack,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      supplierName: supplierName ?? this.supplierName,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isSoftDeleted: isSoftDeleted ?? this.isSoftDeleted,
      stocks: stocks ?? this.stocks,
      looseStock: looseStock ?? this.looseStock,
      logs: logs ?? this.logs,
      variants: variants ?? this.variants,
      hasVariant: hasVariant ?? this.hasVariant,
      isVariant: isVariant ?? this.isVariant,
      loans: loans ?? this.loans,
      isDeletedPermanent: isDeletedPermanent ?? this.isDeletedPermanent,
    );
  }
}
