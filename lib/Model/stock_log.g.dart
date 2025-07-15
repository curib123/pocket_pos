// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockLogAdapter extends TypeAdapter<StockLog> {
  @override
  final int typeId = 4;

  @override
  StockLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockLog(
      id: fields[0] as String,
      productId: fields[1] as String,
      quantity: fields[2] as int,
      isPiece: fields[3] as bool,
      reason: fields[4] as StockOutType,
      remarks: fields[5] as String?,
      dateLogged: fields[6] as DateTime?,
      lastModified: fields[7] as DateTime?,
      deletedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StockLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.isPiece)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.remarks)
      ..writeByte(6)
      ..write(obj.dateLogged)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StockOutTypeAdapter extends TypeAdapter<StockOutType> {
  @override
  final int typeId = 3;

  @override
  StockOutType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StockOutType.sold;
      case 1:
        return StockOutType.expired;
      case 2:
        return StockOutType.damaged;
      case 3:
        return StockOutType.donated;
      case 4:
        return StockOutType.borrowed;
      default:
        return StockOutType.sold;
    }
  }

  @override
  void write(BinaryWriter writer, StockOutType obj) {
    switch (obj) {
      case StockOutType.sold:
        writer.writeByte(0);
        break;
      case StockOutType.expired:
        writer.writeByte(1);
        break;
      case StockOutType.damaged:
        writer.writeByte(2);
        break;
      case StockOutType.donated:
        writer.writeByte(3);
        break;
      case StockOutType.borrowed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockOutTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
