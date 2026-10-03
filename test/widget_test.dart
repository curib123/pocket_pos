import 'package:flutter_test/flutter_test.dart';
import 'package:nextpos/Model/product_model.dart';

void main() {
  test('product payload round-trips for SQLite persistence', () {
    final now = DateTime.utc(2026, 10, 3, 10, 0);
    final product = Product(
      id: 'rice-1',
      name: 'Rice',
      isSoldByPack: false,
      isSoldByPiece: true,
      createdAt: now,
      lastModified: now,
    );

    final restored = Product.fromMap(product.toMap());

    expect(restored.id, product.id);
    expect(restored.name, product.name);
    expect(restored.isSoldByPiece, isTrue);
    expect(restored.lastModified, product.lastModified);
  });
}
