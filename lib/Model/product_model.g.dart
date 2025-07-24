// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      name: fields[1] as String,
      isSoldByPack: fields[3] as bool,
      isSoldByPiece: fields[4] as bool,
      piecesPerPack: fields[5] as int?,
      category: fields[2] as String?,
      unit: fields[6] as String?,
      imagePath: fields[7] as String?,
      barcode: fields[17] as String?,
      createdAt: fields[8] as DateTime,
      lastModified: fields[9] as DateTime,
      deletedAt: fields[10] as DateTime?,
      stocks: (fields[11] as List).cast<ProductStock>(),
      looseStock: fields[12] as LooseStock?,
      logs: (fields[13] as List).cast<StockLog>(),
      hasVariant: fields[14] as bool,
      variants: (fields[15] as List).cast<Product>(),
      isVariant: fields[16] as bool,
      loans: (fields[18] as List).cast<LoanItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.isSoldByPack)
      ..writeByte(4)
      ..write(obj.isSoldByPiece)
      ..writeByte(5)
      ..write(obj.piecesPerPack)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastModified)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.stocks)
      ..writeByte(12)
      ..write(obj.looseStock)
      ..writeByte(13)
      ..write(obj.logs)
      ..writeByte(14)
      ..write(obj.hasVariant)
      ..writeByte(15)
      ..write(obj.variants)
      ..writeByte(16)
      ..write(obj.isVariant)
      ..writeByte(17)
      ..write(obj.barcode)
      ..writeByte(18)
      ..write(obj.loans);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
