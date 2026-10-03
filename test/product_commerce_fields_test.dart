import 'package:flutter_test/flutter_test.dart';
import 'package:nextpos/Model/product_model.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 4, 1);
  final modifiedAt = DateTime.utc(2026, 10, 4, 2);

  test('product pricing and supplier survive serialization', () {
    final product = Product(
      id: 'product-1',
      name: 'Sample Drink',
      category: 'Drinks',
      isSoldByPack: true,
      isSoldByPiece: false,
      unit: 'bottle',
      reorderLevel: 6,
      costPrice: 25.50,
      sellingPrice: 30.00,
      supplierName: 'Shoppers Mall',
      createdAt: createdAt,
      lastModified: modifiedAt,
    );

    final restored = Product.fromMap(product.toMap());

    expect(restored.costPrice, 25.50);
    expect(restored.sellingPrice, 30.00);
    expect(restored.supplierName, 'Shoppers Mall');
  });

  test('legacy product payload gets safe commerce defaults', () {
    final restored = Product.fromMap({
      'id': 'legacy-product',
      'name': 'Legacy Item',
      'category': 'General',
      'isSoldByPack': true,
      'isSoldByPiece': false,
      'piecesPerPack': null,
      'unit': 'pcs',
      'imagePath': null,
      'reorderLevel': 5,
      'barcode': null,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': modifiedAt.toIso8601String(),
      'isSoftDeleted': false,
      'stocks': const [],
      'looseStock': null,
      'logs': const [],
      'hasVariant': false,
      'variants': const [],
      'isVariant': false,
      'loans': const [],
      'isDeletedPermanent': false,
    });

    expect(restored.costPrice, 0);
    expect(restored.sellingPrice, 0);
    expect(restored.supplierName, isNull);
  });

  test('copyWith updates product defaults without changing identity', () {
    final product = Product(
      id: 'product-2',
      name: 'Rice',
      isSoldByPack: true,
      isSoldByPiece: false,
      costPrice: 48,
      sellingPrice: 55,
      supplierName: 'Old Supplier',
      createdAt: createdAt,
      lastModified: modifiedAt,
    );

    final updated = product.copyWith(
      costPrice: 50,
      sellingPrice: 58,
      supplierName: 'Shoppers Mall',
    );

    expect(updated.id, product.id);
    expect(updated.costPrice, 50);
    expect(updated.sellingPrice, 58);
    expect(updated.supplierName, 'Shoppers Mall');
  });
}
