import 'package:flutter_test/flutter_test.dart';
import 'package:nextpos/core/inventory/stock_rules.dart';

void main() {
  group('StockRules', () {
    test('Stock In adds quantity', () {
      expect(StockRules.stockIn(10, 5), 15);
    });

    test('Stock Out subtracts quantity', () {
      expect(StockRules.stockOut(10, 4), 6);
    });

    test('Stock Out prevents negative inventory', () {
      expect(
        () => StockRules.stockOut(3, 4),
        throwsA(isA<StateError>()),
      );
    });

    test('Adjustment keeps signed difference', () {
      expect(StockRules.adjustmentDifference(10, 13), 3);
      expect(StockRules.adjustmentDifference(10, 7), -3);
    });

    test('Adjustment accepts zero actual stock', () {
      expect(StockRules.adjustmentDifference(4, 0), -4);
    });
  });
}
