enum UnitType {
  pcs,
  box,
  pack,
  sack,
  bottle,
  grams,
  kilo,
}

extension UnitTypeExtension on UnitType {
  String get label {
    switch (this) {
      case UnitType.pcs:
        return 'pcs';
      case UnitType.box:
        return 'box';
      case UnitType.pack:
        return 'pack';
      case UnitType.sack:
        return 'sack';
      case UnitType.bottle:
        return 'bottle';
      case UnitType.grams:
        return 'grams';
      case UnitType.kilo:
        return 'kilo';
    }
  }

  static List<String> get valuesAsString =>
      UnitType.values.map((e) => e.label).toList();
}
