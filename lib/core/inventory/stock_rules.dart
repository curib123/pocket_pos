class StockRules {
  static const int maxStock = 2147483647;

  static int validateStockValue(int value) {
    if (value < 0 || value > maxStock) {
      throw ArgumentError('Stock must be between 0 and ' + maxStock.toString() + '.');
    }
    return value;
  }

  static int validateQuantity(int quantity) {
    if (quantity <= 0 || quantity > maxStock) {
      throw ArgumentError('Quantity must be between 1 and ' + maxStock.toString() + '.');
    }
    return quantity;
  }

  static int stockIn(int currentStock, int quantity) {
    validateStockValue(currentStock);
    validateQuantity(quantity);
    if (currentStock > maxStock - quantity) {
      throw ArgumentError('Stock quantity is too large.');
    }
    return currentStock + quantity;
  }

  static int stockOut(int currentStock, int quantity) {
    validateStockValue(currentStock);
    validateQuantity(quantity);
    if (quantity > currentStock) {
      throw StateError(
        'Insufficient stock. Available: ' +
            currentStock.toString() +
            ', requested: ' +
            quantity.toString() +
            '.',
      );
    }
    return currentStock - quantity;
  }

  static int adjustmentDifference(int systemStock, int actualStock) {
    validateStockValue(systemStock);
    validateStockValue(actualStock);
    return actualStock - systemStock;
  }
}
