// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loose_stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LooseStockAdapter extends TypeAdapter<LooseStock> {
  @override
  final int typeId = 2;

  @override
  LooseStock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LooseStock(
      productId: fields[0] as String,
      remainingPieces: fields[1] as int,
      lastModified: fields[2] as DateTime?,
      deletedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LooseStock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.remainingPieces)
      ..writeByte(2)
      ..write(obj.lastModified)
      ..writeByte(3)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LooseStockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
