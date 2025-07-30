
String getSellingTypeGuide({
  required bool isSoldByPack,
  required bool isSoldByPiece,
}) {
  if (isSoldByPack && isSoldByPiece) {
    return 'Customers can buy either full packs or individual pieces. e.g. a box of canned soda or a single can.';
  } else if (isSoldByPack) {
    return 'This product is only sold in full packs. e.g. a 6-pack of bottled water.';
  } else if (isSoldByPiece) {
    return 'This product is only sold per piece. e.g. a single candy bar or bottled drink.';
  } else {
    return 'Choose at least one selling method: pack, piece, or both. e.g. You might sell bottled water by the case (pack) or by the bottle (piece).';
  }
}

String getUnitType({
  required bool isSoldByPack,
  required bool isSoldByPiece,
}) {
  if (isSoldByPack) return 'pack';
  if (isSoldByPiece) return 'piece';
  return 'unit';
}

