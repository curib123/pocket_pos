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

  LoanPerson({
    required this.name,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.date,
    this.isPaid = false,
  });
}
