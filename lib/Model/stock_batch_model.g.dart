// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_batch_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockBatchAdapter extends TypeAdapter<StockBatch> {
  @override
  final int typeId = 3;

  @override
  StockBatch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockBatch(
      batchId: fields[0] as String,
      productId: fields[1] as String,
      quantity: fields[2] as int,
      quantitySold: fields[3] as int,
      receivedDate: fields[4] as DateTime,
      supplier: fields[5] as String?,
      expiryDate: fields[6] as DateTime?,
      costPrice: fields[7] as double?,
      isDeleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StockBatch obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.batchId)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.quantitySold)
      ..writeByte(4)
      ..write(obj.receivedDate)
      ..writeByte(5)
      ..write(obj.supplier)
      ..writeByte(6)
      ..write(obj.expiryDate)
      ..writeByte(7)
      ..write(obj.costPrice)
      ..writeByte(8)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockBatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
