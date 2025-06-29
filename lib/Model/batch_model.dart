import 'package:hive/hive.dart';

part 'batch_model.g.dart';

@HiveType(typeId: 1)
class Batch {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  double quantity;

  Batch({required this.date, required this.quantity});
}
