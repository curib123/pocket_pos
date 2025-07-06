import 'package:hive/hive.dart';

part 'loan_person_model.g.dart';

@HiveType(typeId: 2)
class LoanPerson extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String productId;

  @HiveField(2)
  String productName;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double totalAmount;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  bool isPaid;

  @HiveField(7)
  DateTime lastModified; // <-- Added for Sync Support

  LoanPerson({
    required this.name,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.date,
    this.isPaid = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  /// Save loan with updated timestamp
  Future<void> saveWithTimestamp() {
    lastModified = DateTime.now();
    return save();
  }

  /// For server sync (toMap)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
      'is_paid': isPaid,
      'last_modified': lastModified.toIso8601String(),
    };
  }

  /// From server JSON (map)
  factory LoanPerson.fromMap(Map<String, dynamic> map) {
    return LoanPerson(
      name: map['name'],
      productId: map['product_id'],
      productName: map['product_name'],
      quantity: (map['quantity'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      isPaid: map['is_paid'] ?? false,
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'])
          : DateTime.now(),
    );
  }
}
