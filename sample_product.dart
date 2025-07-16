import 'package:mobile_pos_inventory/Model/loose_stock.dart';
import 'package:mobile_pos_inventory/Model/product_model.dart';
import 'package:mobile_pos_inventory/Model/product_stock.dart';
import 'package:mobile_pos_inventory/Model/stock_log.dart';

final sampleProduct = Product(
  id: 'prod001',
  name: 'Marlboro Red',
  category: 'Cigarettes',
  isSoldByPack: true, // ✅ By Pack
  isSoldByPiece: true, // ✅ AND By Piece
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
      quantity: 10,
      costPrice: 80.0,
      retailPrice: 120.0,
      dateReceived: DateTime.now().subtract(Duration(days: 10)),
    ),
    ProductStock(
      id: 'stock002',
      productId: 'prod001',
      quantity: 5,
      costPrice: 85.0,
      retailPrice: 130.0,
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
  hasVariant: true,
  variants: [
    // 🔵 By Pack + Piece
    Product(
      id: 'prod001-v1',
      name: 'Marlboro Red (100s)',
      category: 'Cigarettes',
      isSoldByPack: true,
      isSoldByPiece: true,
      piecesPerPack: 20,
      unit: 'pcs',
      imagePath: 'assets/images/marlboro_100s.png',
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      lastModified: DateTime.now(),
      deletedAt: null,
      stocks: [
        ProductStock(
          id: 'stock-v1-001',
          productId: 'prod001-v1',
          quantity: 8,
          costPrice: 90.0,
          retailPrice: 135.0,
          dateReceived: DateTime.now().subtract(Duration(days: 7)),
        ),
      ],
      looseStock: LooseStock(
        productId: 'prod001-v1',
        remainingPieces: 5,
        lastModified: DateTime.now(),
      ),
      logs: [],
      hasVariant: false,
      variants: [],
    ),

    // 🔵 Only By Pack
    Product(
      id: 'prod001-v2',
      name: 'Marlboro Red (Soft Pack)',
      category: 'Cigarettes',
      isSoldByPack: true,
      isSoldByPiece: false,
      piecesPerPack: 20,
      unit: 'pcs',
      imagePath: 'assets/images/marlboro_soft.png',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      lastModified: DateTime.now(),
      deletedAt: null,
      stocks: [
        ProductStock(
          id: 'stock-v2-001',
          productId: 'prod001-v2',
          quantity: 12,
          costPrice: 75.0,
          retailPrice: 110.0,
          dateReceived: DateTime.now().subtract(Duration(days: 5)),
        ),
      ],
      logs: [
        StockLog(
          id: 'log-v2-001',
          productId: 'prod001-v2',
          quantity: 2,
          isPiece: false,
          reason: StockOutType.damaged,
          remarks: 'Crushed pack',
          dateLogged: DateTime.now().subtract(Duration(days: 1)),
        ),
      ],
      looseStock: null,
      hasVariant: false,
      variants: [],
    ),

    // 🔵 Only By Piece (no full packs)
    Product(
      id: 'prod001-v3',
      name: 'Marlboro Red (Loose Only)',
      category: 'Cigarettes',
      isSoldByPack: false,
      isSoldByPiece: true,
      piecesPerPack: 20,
      unit: 'pcs',
      imagePath: 'assets/images/marlboro_loose.png',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      lastModified: DateTime.now(),
      deletedAt: null,
      stocks: [
        ProductStock(
          id: 'stock-v3-001',
          productId: 'prod001-v3',
          quantity: 0,
          costPrice: 0.0,
          retailPrice: 0.0,
          dateReceived: DateTime.now().subtract(Duration(days: 3)),
        ),
      ],
      looseStock: LooseStock(
        productId: 'prod001-v3',
        remainingPieces: 30,
        lastModified: DateTime.now(),
      ),
      logs: [],
      hasVariant: false,
      variants: [],
    ),
  ],
);
