import 'package:hive/hive.dart';
import 'package:paninda/Model/product_model.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 3)
class CartItem extends HiveObject {
  @HiveField(0)
  Product product;

  @HiveField(1)
  double quantity;

  @HiveField(2)
  bool isKilo;

  @HiveField(3)
  bool isLoan;

  @HiveField(4)
  double buyerCash;

  @HiveField(5)
  String borrowerName;

  CartItem({
    required this.product,
    required this.quantity,
    required this.isKilo,
    required this.isLoan,
    required this.buyerCash,
    required this.borrowerName,
  });
}
