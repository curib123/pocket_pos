import 'package:hive/hive.dart';

part 'addon_model.g.dart';

@HiveType(typeId: 2)
class Addon extends HiveObject {
  @HiveField(0)
  String addonId;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  bool isRequired;

  @HiveField(4)
  int maxQuantity;

  @HiveField(5)
  List<String>? appliesTo;

  @HiveField(6)
  bool isDeleted;

  Addon({
    required this.addonId,
    required this.name,
    required this.price,
    this.isRequired = false,
    this.maxQuantity = 1,
    this.appliesTo,
    this.isDeleted = false,
  });

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      addonId: json['addonId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] ?? false,
      maxQuantity: json['maxQuantity'] ?? 1,
      appliesTo: json['appliesTo'] != null
          ? List<String>.from(json['appliesTo'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addonId': addonId,
      'name': name,
      'price': price,
      'isRequired': isRequired,
      'maxQuantity': maxQuantity,
      'appliesTo': appliesTo,
      'isDeleted': isDeleted,
    };
  }
}
