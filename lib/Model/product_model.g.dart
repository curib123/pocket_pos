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
      type: fields[4] as String,
      status: fields[5] as String,
      description: fields[2] as String?,
      category: fields[3] as String?,
      sku: fields[6] as String?,
      barcode: fields[7] as String?,
      defaultPrice: fields[8] as double?,
      costPrice: fields[9] as double?,
      taxRate: fields[10] as double?,
      discount: fields[11] as double?,
      isActive: fields[12] as bool,
      isDeleted: fields[13] as bool,
      images: (fields[14] as List?)?.cast<String>(),
      mainImage: fields[15] as String?,
      hasVariants: fields[16] as bool,
      variantIds: (fields[17] as List?)?.cast<String>(),
      addonIds: (fields[18] as List?)?.cast<String>(),
      stockBatchIds: (fields[19] as List?)?.cast<String>(),
      unit: fields[20] as String?,
      unitType: fields[21] as String?,
      unitConversion: fields[22] as double?,
      unitPriceBasis: fields[23] as String?,
      attributes: (fields[24] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[25] as DateTime?,
      updatedAt: fields[26] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.sku)
      ..writeByte(7)
      ..write(obj.barcode)
      ..writeByte(8)
      ..write(obj.defaultPrice)
      ..writeByte(9)
      ..write(obj.costPrice)
      ..writeByte(10)
      ..write(obj.taxRate)
      ..writeByte(11)
      ..write(obj.discount)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.isDeleted)
      ..writeByte(14)
      ..write(obj.images)
      ..writeByte(15)
      ..write(obj.mainImage)
      ..writeByte(16)
      ..write(obj.hasVariants)
      ..writeByte(17)
      ..write(obj.variantIds)
      ..writeByte(18)
      ..write(obj.addonIds)
      ..writeByte(19)
      ..write(obj.stockBatchIds)
      ..writeByte(20)
      ..write(obj.unit)
      ..writeByte(21)
      ..write(obj.unitType)
      ..writeByte(22)
      ..write(obj.unitConversion)
      ..writeByte(23)
      ..write(obj.unitPriceBasis)
      ..writeByte(24)
      ..write(obj.attributes)
      ..writeByte(25)
      ..write(obj.createdAt)
      ..writeByte(26)
      ..write(obj.updatedAt);
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
