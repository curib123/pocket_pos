import 'package:hive/hive.dart';

part 'batch_model.g.dart';

@HiveType(typeId: 1)
class Batch {
  @HiveField(0)
  String id;

  @HiveField(1)
  double quantity; // ✅ Number of pieces/units

  @HiveField(2)
  DateTime createdAt;

  Batch({
    required this.id,
    required this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Batch copyWith({
    String? id,
    double? quantity,
    DateTime? createdAt,
  }) {
    return Batch(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}
