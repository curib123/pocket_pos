import 'package:mobile_pos_inventory/Helper/Enums/enum.dart';

extension ProductTypeExtension on ProductType {
  String get label {
    switch (this) {
      case ProductType.single:
        return 'Single';
      case ProductType.bundle:
        return 'Bundle';
    }
  }
}

extension ProductStatusExtension on ProductStatus {
  String get label {
    switch (this) {
      case ProductStatus.available:
        return 'Available';
      case ProductStatus.outOfStock:
        return 'Out of Stock';
      case ProductStatus.archived:
        return 'Archived';
    }
  }
}

extension UnitExtension on Unit {
  String get label {
    switch (this) {
      case Unit.piece:
        return 'Piece';
      case Unit.pack:
        return 'Pack';
      case Unit.kilo:
        return 'Kilo';
      case Unit.liter:
        return 'Liter';
      case Unit.meter:
        return 'Meter';
      case Unit.box:
        return 'Box';
    }
  }
}

extension UnitTypeExtension on UnitType {
  String get label {
    switch (this) {
      case UnitType.weight:
        return 'Weight';
      case UnitType.volume:
        return 'Volume';
      case UnitType.length:
        return 'Length';
      case UnitType.count:
        return 'Count';
    }
  }
}
