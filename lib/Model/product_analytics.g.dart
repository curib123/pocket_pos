// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_analytics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAnalyticsAdapter extends TypeAdapter<ProductAnalytics> {
  @override
  final int typeId = 5;

  @override
  ProductAnalytics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductAnalytics(
      productId: fields[0] as String,
      totalQuantity: fields[1] as int,
      loosePieces: fields[2] as int,
      averageCostPrice: fields[3] as double,
      latestRetailPrice: fields[4] as double,
      soldPacks: fields[5] as int,
      soldPieces: fields[6] as int,
      expired: fields[7] as int,
      damaged: fields[8] as int,
      donated: fields[9] as int,
      borrowed: fields[10] as int,
      totalRevenue: fields[11] as double,
      totalCost: fields[12] as double,
      totalProfit: fields[13] as double,
      timesSold: fields[14] as int,
      totalUnitsSold: fields[15] as int,
      isBestSeller: fields[16] as bool,
      isLowPerformer: fields[17] as bool,
      lastUpdated: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductAnalytics obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.totalQuantity)
      ..writeByte(2)
      ..write(obj.loosePieces)
      ..writeByte(3)
      ..write(obj.averageCostPrice)
      ..writeByte(4)
      ..write(obj.latestRetailPrice)
      ..writeByte(5)
      ..write(obj.soldPacks)
      ..writeByte(6)
      ..write(obj.soldPieces)
      ..writeByte(7)
      ..write(obj.expired)
      ..writeByte(8)
      ..write(obj.damaged)
      ..writeByte(9)
      ..write(obj.donated)
      ..writeByte(10)
      ..write(obj.borrowed)
      ..writeByte(11)
      ..write(obj.totalRevenue)
      ..writeByte(12)
      ..write(obj.totalCost)
      ..writeByte(13)
      ..write(obj.totalProfit)
      ..writeByte(14)
      ..write(obj.timesSold)
      ..writeByte(15)
      ..write(obj.totalUnitsSold)
      ..writeByte(16)
      ..write(obj.isBestSeller)
      ..writeByte(17)
      ..write(obj.isLowPerformer)
      ..writeByte(18)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAnalyticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
