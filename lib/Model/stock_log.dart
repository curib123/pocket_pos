import 'package:hive/hive.dart';

part 'stock_log.g.dart';

@HiveType(typeId: 3)
enum StockLogReason {
  @HiveField(0)
  sold,

  @HiveField(1)
  expired,

  @HiveField(2)
  damaged,

  @HiveField(3)
  donated,

  @HiveField(4)
  borrowed,

  @HiveField(5)
  added,       // ➕ Initial stock entry

  @HiveField(6)
  restocked,   // 🔁 Manual stock in

  @HiveField(7)
  adjusted,    // ✏️ Manual stock update/edit

  @HiveField(8)
  deleted,     // ❌ Product archived or deleted

  @HiveField(9)
  restored,    // ♻️ Product restored from archive

  @HiveField(10)
  cleared,     // 🧹 Product wiped in bulk clear
}

@HiveType(typeId: 4)
class StockLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final bool isPiece;

  @HiveField(4)
  final StockLogReason reason;

  @HiveField(5)
  final String? remarks;

  @HiveField(6)
  final DateTime dateLogged;

  @HiveField(7)
  final DateTime lastModified;

  @HiveField(8)
  final DateTime? deletedAt;

  StockLog({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.isPiece,
    required this.reason,
    this.remarks,
    DateTime? dateLogged,
    DateTime? lastModified,
    this.deletedAt,
  })  : dateLogged = dateLogged ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'isPiece': isPiece,
      'reason': reason.name,
      'remarks': remarks,
      'dateLogged': dateLogged.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory StockLog.fromMap(Map<String, dynamic> map) {
    return StockLog(
      id: map['id'],
      productId: map['productId'],
      quantity: map['quantity'],
      isPiece: map['isPiece'],
      reason: StockLogReason.values.firstWhere(
            (e) => e.name == map['reason'],
        orElse: () => StockLogReason.sold,
      ),
      remarks: map['remarks'],
      dateLogged: DateTime.parse(map['dateLogged']),
      lastModified: DateTime.parse(map['lastModified']),
      deletedAt: map['deletedAt'] != null
          ? DateTime.parse(map['deletedAt'])
          : null,
    );
  }

  StockLog copyWith({
    String? id,
    String? productId,
    int? quantity,
    bool? isPiece,
    StockLogReason? reason,
    String? remarks,
    DateTime? dateLogged,
    DateTime? lastModified,
    DateTime? deletedAt,
  }) {
    return StockLog(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      isPiece: isPiece ?? this.isPiece,
      reason: reason ?? this.reason,
      remarks: remarks ?? this.remarks,
      dateLogged: dateLogged ?? this.dateLogged,
      lastModified: lastModified ?? this.lastModified,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
