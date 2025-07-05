import 'package:hive/hive.dart';

part 'batch_model.g.dart';

@HiveType(typeId: 1)
class Batch extends HiveObject {
  @HiveField(0)
  double quantity; // e.g., number of sacks or bags

  @HiveField(1)
  double kiloQuantity; // weight in kilos

  @HiveField(2)
  DateTime date;

  Batch({
    required this.quantity,
    required this.kiloQuantity,
    required this.date,
  });

  /// For Supabase or JSON
  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'kilo_quantity': kiloQuantity,
      'date': date.toIso8601String(),
    };
  }

  /// External Mapper (for Supabase or JSON)
  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      quantity: (map['quantity'] as num).toDouble(),
      kiloQuantity: (map['kilo_quantity'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
