import 'package:hive/hive.dart';

part 'loose_stock.g.dart';

@HiveType(typeId: 2)
class LooseStock extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  int remainingPieces;

  @HiveField(2)
  final DateTime lastModified;

  @HiveField(3)
  final DateTime? deletedAt;

  LooseStock({
    required this.productId,
    required this.remainingPieces,
    DateTime? lastModified,
    this.deletedAt,
  }) : lastModified = lastModified ?? DateTime.now();

  // ✅ toMap
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'remainingPieces': remainingPieces,
      'lastModified': lastModified.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // ✅ fromMap
  factory LooseStock.fromMap(Map<String, dynamic> map) {
    return LooseStock(
      productId: map['productId'],
      remainingPieces: map['remainingPieces'],
      lastModified: DateTime.parse(map['lastModified']),
      deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt']) : null,
    );
  }

  // ✅ copyWith
  LooseStock copyWith({
    String? productId,
    int? remainingPieces,
    DateTime? lastModified,
    DateTime? deletedAt,
  }) {
    return LooseStock(
      productId: productId ?? this.productId,
      remainingPieces: remainingPieces ?? this.remainingPieces,
      lastModified: lastModified ?? this.lastModified,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
