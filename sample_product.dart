import 'package:mobile_pos_inventory/Model/loose_stock.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/product_stock.dart';
import 'package:mobile_pos_inventory/Model/stock_log.dart';

final sampleProduct = Product(
  id: 'prod001',
  name: 'Marlboro Red',
  category: 'Cigarettes',
  isSoldByPack: true,
  isSoldByPiece: true,
  piecesPerPack: 20,
  unit: 'pcs',
  imagePath: 'assets/images/marlboro.png',
  createdAt: DateTime.now().subtract(Duration(days: 10)),
  lastModified: DateTime.now(),
  deletedAt: null,
  stocks: [
    ProductStock(
      id: 'stock001',
      productId: 'prod001',
      quantity: 10, // 10 packs
      costPrice: 80.0,
      dateReceived: DateTime.now().subtract(Duration(days: 10)),
    ),
    ProductStock(
      id: 'stock002',
      productId: 'prod001',
      quantity: 5, // newer stock
      costPrice: 85.0,
      dateReceived: DateTime.now().subtract(Duration(days: 3)),
    ),
  ],
  looseStock: LooseStock(
    productId: 'prod001',
    remainingPieces: 12,
    lastModified: DateTime.now(),
  ),
  logs: [
    StockLog(
      id: 'log001',
      productId: 'prod001',
      quantity: 1,
      isPiece: false,
      reason: StockOutType.sold,
      remarks: 'Sold 1 pack',
      dateLogged: DateTime.now().subtract(Duration(days: 1)),
    ),
    StockLog(
      id: 'log002',
      productId: 'prod001',
      quantity: 8,
      isPiece: true,
      reason: StockOutType.sold,
      remarks: 'Sold 8 sticks',
      dateLogged: DateTime.now().subtract(Duration(hours: 6)),
    ),
  ],
);
