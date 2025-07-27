import 'package:hive/hive.dart';
import 'product_stock.dart';
import 'loose_stock.dart';
import 'stock_log.dart';
import 'loan_item.dart'; // 🆕 Import LoanItem

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? category;

  @HiveField(3)
  final bool isSoldByPack;

  @HiveField(4)
  final bool isSoldByPiece;

  @HiveField(5)
  final int? piecesPerPack;

  @HiveField(6)
  final String? unit;

  @HiveField(7)
  final String? imagePath;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime lastModified;

  @HiveField(10)
  final bool isSoftDeleted; // 🆕 replaces deletedAt

  @HiveField(11)
  final List<ProductStock> stocks;

  @HiveField(12)
  final LooseStock? looseStock;

  @HiveField(13)
  final List<StockLog> logs;

  @HiveField(14)
  final bool hasVariant;

  @HiveField(15)
  final List<Product> variants;

  @HiveField(16)
  final bool isVariant;

  @HiveField(17)
  final String? barcode;

  @HiveField(18)
  final List<LoanItem> loans;

  @HiveField(19)
  final bool isDeletedPermanent;

  // 🔢 Computed
  int get totalQuantity => stocks.fold(0, (sum, stock) => sum + stock.quantity);

  int get totalQuantityByPieces =>
      totalQuantity * (piecesPerPack ?? 1);

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
    this.barcode,
    required this.createdAt,
    required this.lastModified,
    this.isSoftDeleted = false, // 🆕 default false
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
      'barcode': barcode,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'isSoftDeleted': isSoftDeleted, // ✅
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
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      isSoldByPack: map['isSoldByPack'],
      isSoldByPiece: map['isSoldByPiece'],
      piecesPerPack: map['piecesPerPack'],
      unit: map['unit'],
      imagePath: map['imagePath'],
      barcode: map['barcode'],
      createdAt: DateTime.parse(map['createdAt']),
      lastModified: DateTime.parse(map['lastModified']),
      isSoftDeleted: map['isSoftDeleted'] ?? false, // ✅
      stocks: (map['stocks'] as List?)?.map((s) => ProductStock.fromMap(s)).toList() ?? [],
      looseStock: map['looseStock'] != null ? LooseStock.fromMap(map['looseStock']) : null,
      logs: (map['logs'] as List?)?.map((l) => StockLog.fromMap(l)).toList() ?? [],
      hasVariant: map['hasVariant'] ?? false,
      variants: (map['variants'] as List?)?.map((v) => Product.fromMap(v)).toList() ?? [],
      isVariant: map['isVariant'] ?? false,
      loans: (map['loans'] as List?)?.map((l) => LoanItem.fromMap(l)).toList() ?? [],
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
    String? barcode,
    DateTime? createdAt,
    DateTime? lastModified,
    bool? isSoftDeleted, // ✅
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
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      isSoftDeleted: isSoftDeleted ?? this.isSoftDeleted, // ✅
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
