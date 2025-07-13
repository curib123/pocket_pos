enum UnitType {
  pcs, // e.g., stick, piece
  pack,     // e.g., pack, box, sack, etc.
}

extension UnitTypeExtension on UnitType {
  /// Returns a readable label for UI
  String get label {
    switch (this) {
      case UnitType.pcs:
        return 'Per Piece';
      case UnitType.pack:
        return 'Per Pack';
    }
  }

  /// List of all unit type labels (for dropdowns)
  static List<String> get valuesAsString =>
      UnitType.values.map((e) => e.label).toList();

  /// Convert from label string (e.g., from dropdown selection)
  static UnitType fromLabel(String label) {
    final l = label.toLowerCase();
    return UnitType.values.firstWhere(
          (e) => e.label.toLowerCase() == l,
      orElse: () => UnitType.pcs,
    );
  }

  /// Whether the unit type supports sub-quantities (like items inside a bundle)
  static bool supportsSubQuantity(String? label) {
    return fromLabel(label ?? '') == UnitType.pack;
  }

  /// JSON-compatible string value
  String toJson() => label;

  /// Deserialize from JSON string
  static UnitType fromJson(String label) => fromLabel(label);

}
