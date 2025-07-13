import 'package:hive/hive.dart';

part 'batch_model.g.dart';

@HiveType(typeId: 1)
class Batch {
  @HiveField(0)
  String id;

  @HiveField(1)
  double quantity; // Number of packs (or main unit)

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  double? subQuantity; // Optional: sub-units per main unit (e.g., sticks per pack)

  Batch({
    required this.id,
    required this.quantity,
    required this.createdAt,
    this.subQuantity,
  });


  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  Batch copyWith({
    String? id,
    double? quantity,
    DateTime? createdAt,
    double? subQuantity,
  }) {
    return Batch(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      subQuantity: subQuantity ?? this.subQuantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'sub_quantity': subQuantity,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      quantity: (map['quantity'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      subQuantity: map['sub_quantity'] != null ? (map['sub_quantity'] as num).toDouble() : null,
    );
  }

  @override
  String toString() {
    return 'Batch(id: $id, quantity: $quantity, subQuantity: $subQuantity, createdAt: $createdAt)';
  }
}
