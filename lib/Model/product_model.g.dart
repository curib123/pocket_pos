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
      unit: fields[2] as String,
      batches: (fields[3] as List).cast<Batch>(),
      description: fields[4] as String,
      imageUrl: fields[5] as String,
      category: fields[6] as String,
      lastModified: fields[7] as DateTime,
      defaultCost: fields[9] as double,
      defaultRetail: fields[10] as double,
      isPack: fields[11] as bool,
      packItems: fields[12] as double,
      packItemsCost: fields[13] as double,
      packItemsRetail: fields[14] as double,
      profitMargin: fields[15] as double,
      deletedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.batches)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.deletedAt)
      ..writeByte(9)
      ..write(obj.defaultCost)
      ..writeByte(10)
      ..write(obj.defaultRetail)
      ..writeByte(11)
      ..write(obj.isPack)
      ..writeByte(12)
      ..write(obj.packItems)
      ..writeByte(13)
      ..write(obj.packItemsCost)
      ..writeByte(14)
      ..write(obj.packItemsRetail)
      ..writeByte(15)
      ..write(obj.profitMargin);
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
