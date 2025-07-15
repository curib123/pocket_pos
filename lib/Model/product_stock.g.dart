// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductStockAdapter extends TypeAdapter<ProductStock> {
  @override
  final int typeId = 1;

  @override
  ProductStock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductStock(
      id: fields[0] as String,
      productId: fields[1] as String,
      quantity: fields[2] as int,
      costPrice: fields[3] as double,
      dateReceived: fields[4] as DateTime,
      lastModified: fields[5] as DateTime?,
      deletedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductStock obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.costPrice)
      ..writeByte(4)
      ..write(obj.dateReceived)
      ..writeByte(5)
      ..write(obj.lastModified)
      ..writeByte(6)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductStockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
