import 'package:hive/hive.dart';
import 'batch_model.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double costPrice; // renamed from 'price'

  @HiveField(3)
  double retailPrice; // added field

  @HiveField(4)
  String unit;

  @HiveField(5)
  List<Batch> batches;

  @HiveField(6)
  String description;

  @HiveField(7)
  String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.retailPrice,
    required this.unit,
    required this.batches,
    required this.description,
    required this.imageUrl,
  });

  double get totalQuantity =>
      batches.fold(0, (sum, batch) => sum + batch.quantity);

  double get totalCostValue => totalQuantity * costPrice;

  double get totalRetailValue => totalQuantity * retailPrice;
}
