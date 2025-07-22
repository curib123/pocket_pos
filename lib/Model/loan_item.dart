import 'package:hive/hive.dart';

part 'loan_item.g.dart'; // 🛠️ Needed for code generation

@HiveType(typeId: 6)
class LoanItem extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  final int maxQuantity;

  @HiveField(5)
  final String? imagePath;

  @HiveField(6)
  final String? barcode;

  @HiveField(7)
  final String borrowerName;

  @HiveField(8)
  final DateTime loanDate;

  @HiveField(9)
  final DateTime? dueDate;

  @HiveField(10)
  bool isReturned;

  @HiveField(11)
  double amount;

  @HiveField(12)
  double paid;

  @HiveField(13)
  DateTime? returnDate;

  LoanItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.maxQuantity = 999,
    this.imagePath,
    this.barcode,
    required this.borrowerName,
    required this.loanDate,
    this.dueDate,
    this.isReturned = false,
    double? amount,
    this.paid = 0.0,
    this.returnDate,
  }) : amount = amount ?? (price * quantity);

  double get balance => amount - paid;

  double getSubtotal() => price * quantity;

  bool get isFullyPaid => balance <= 0;

  LoanItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    int? maxQuantity,
    String? imagePath,
    String? barcode,
    String? borrowerName,
    DateTime? loanDate,
    DateTime? dueDate,
    bool? isReturned,
    double? amount,
    double? paid,
    DateTime? returnDate,
  }) {
    return LoanItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      imagePath: imagePath ?? this.imagePath,
      barcode: barcode ?? this.barcode,
      borrowerName: borrowerName ?? this.borrowerName,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      isReturned: isReturned ?? this.isReturned,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      returnDate: returnDate ?? this.returnDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'maxQuantity': maxQuantity,
      'imagePath': imagePath,
      'barcode': barcode,
      'borrowerName': borrowerName,
      'loanDate': loanDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isReturned': isReturned,
      'amount': amount,
      'paid': paid,
      'returnDate': returnDate?.toIso8601String(),
    };
  }

  factory LoanItem.fromMap(Map<String, dynamic> map) {
    return LoanItem(
      productId: map['productId'],
      name: map['name'],
      price: map['price'],
      quantity: map['quantity'],
      maxQuantity: map['maxQuantity'] ?? 999,
      imagePath: map['imagePath'],
      barcode: map['barcode'],
      borrowerName: map['borrowerName'],
      loanDate: DateTime.parse(map['loanDate']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isReturned: map['isReturned'] ?? false,
      amount: map['amount'] ?? (map['price'] * map['quantity']),
      paid: map['paid'] ?? 0.0,
      returnDate: map['returnDate'] != null ? DateTime.parse(map['returnDate']) : null,
    );
  }
}
