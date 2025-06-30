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
}
