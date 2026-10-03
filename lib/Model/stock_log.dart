enum StockLogReason {
  sold,
  expired,
  damaged,
  donated,
  borrowed,
  added,       // ➕ Initial stock entry
  restocked,   // 🔁 Manual stock in
  adjusted,    // ✏️ Manual stock update/edit
  deleted,     // ❌ Product archived or deleted
  restored,    // ♻️ Product restored from archive
  cleared,     // 🧹 Product wiped in bulk clear
  consumed,
  unknown,     // 🚨 Fallback enum for unexpected strings
  stockIn,
  stockOut,
  stockAdjustment,
}
class StockLog {
  final String id;
  final String productId;
  final int quantity;
  final bool isPiece;
  final StockLogReason reason;
  final String? remarks;
  final DateTime dateLogged;
  final DateTime lastModified;
  final DateTime? deletedAt;
  final double? profit;

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
    this.profit,
  })  : dateLogged = dateLogged ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'isPiece': isPiece,
      'reason': reason.name,
      'remarks': remarks ?? '',
      'dateLogged': dateLogged.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'profit': profit ?? 0.0,
    };
  }

  factory StockLog.fromMap(Map<String, dynamic> map) {
    return StockLog(
      id: map['id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '',
      quantity: int.tryParse(map['quantity'].toString()) ?? 0,
      isPiece: map['isPiece'] == true,
      profit: map['profit'] != null
          ? double.tryParse(map['profit'].toString()) ?? 0.0
          : 0.0,
      reason: StockLogReason.values.firstWhere(
            (e) => e.name == map['reason'],
        orElse: () => StockLogReason.unknown,
      ),
      remarks: map['remarks']?.toString(),
      dateLogged: DateTime.tryParse(map['dateLogged'] ?? '') ?? DateTime.now(),
      lastModified:
      DateTime.tryParse(map['lastModified'] ?? '') ?? DateTime.now(),
      deletedAt: (map['deletedAt'] != null &&
          map['deletedAt'].toString().isNotEmpty)
          ? DateTime.tryParse(map['deletedAt'])
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
    double? profit,
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
      profit: profit ?? this.profit,
    );
  }
}
