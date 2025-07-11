// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VariantAdapter extends TypeAdapter<Variant> {
  @override
  final int typeId = 1;

  @override
  Variant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Variant(
      variantId: fields[0] as String,
      productId: fields[1] as String,
      name: fields[2] as String,
      sku: fields[3] as String?,
      barcode: fields[4] as String?,
      price: fields[5] as double?,
      costPrice: fields[6] as double?,
      stockQuantity: fields[7] as int?,
      reorderLevel: fields[8] as int?,
      images: (fields[9] as List?)?.cast<String>(),
      mainImage: fields[10] as String?,
      unit: fields[11] as String?,
      unitType: fields[12] as String?,
      unitConversion: fields[13] as double?,
      unitPriceBasis: fields[14] as String?,
      isDeleted: fields[15] as bool,
      createdAt: fields[16] as DateTime?,
      updatedAt: fields[17] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Variant obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.variantId)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.sku)
      ..writeByte(4)
      ..write(obj.barcode)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.costPrice)
      ..writeByte(7)
      ..write(obj.stockQuantity)
      ..writeByte(8)
      ..write(obj.reorderLevel)
      ..writeByte(9)
      ..write(obj.images)
      ..writeByte(10)
      ..write(obj.mainImage)
      ..writeByte(11)
      ..write(obj.unit)
      ..writeByte(12)
      ..write(obj.unitType)
      ..writeByte(13)
      ..write(obj.unitConversion)
      ..writeByte(14)
      ..write(obj.unitPriceBasis)
      ..writeByte(15)
      ..write(obj.isDeleted)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
