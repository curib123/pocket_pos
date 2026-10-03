class LoanItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final int maxQuantity;
  final String? imagePath;
  final String? barcode;
  final String borrowerName;
  final DateTime loanDate;
  final DateTime? dueDate;
  bool isReturned;
  double amount;
  double paid;
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
