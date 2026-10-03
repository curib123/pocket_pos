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
      reason: fields[4] as StockLogReason,
      remarks: fields[5] as String?,
      dateLogged: fields[6] as DateTime?,
      lastModified: fields[7] as DateTime?,
      deletedAt: fields[8] as DateTime?,
      profit: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, StockLog obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.deletedAt)
      ..writeByte(9)
      ..write(obj.profit);
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

class StockLogReasonAdapter extends TypeAdapter<StockLogReason> {
  @override
  final int typeId = 3;

  @override
  StockLogReason read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StockLogReason.sold;
      case 1:
        return StockLogReason.expired;
      case 2:
        return StockLogReason.damaged;
      case 3:
        return StockLogReason.donated;
      case 4:
        return StockLogReason.borrowed;
      case 5:
        return StockLogReason.added;
      case 6:
        return StockLogReason.restocked;
      case 7:
        return StockLogReason.adjusted;
      case 8:
        return StockLogReason.deleted;
      case 9:
        return StockLogReason.restored;
      case 10:
        return StockLogReason.cleared;
      case 11:
        return StockLogReason.consumed;
      case 12:
        return StockLogReason.unknown;
      case 13:
        return StockLogReason.stockIn;
      case 14:
        return StockLogReason.stockOut;
      case 15:
        return StockLogReason.stockAdjustment;
      default:
        return StockLogReason.sold;
    }
  }

  @override
  void write(BinaryWriter writer, StockLogReason obj) {
    switch (obj) {
      case StockLogReason.sold:
        writer.writeByte(0);
        break;
      case StockLogReason.expired:
        writer.writeByte(1);
        break;
      case StockLogReason.damaged:
        writer.writeByte(2);
        break;
      case StockLogReason.donated:
        writer.writeByte(3);
        break;
      case StockLogReason.borrowed:
        writer.writeByte(4);
        break;
      case StockLogReason.added:
        writer.writeByte(5);
        break;
      case StockLogReason.restocked:
        writer.writeByte(6);
        break;
      case StockLogReason.adjusted:
        writer.writeByte(7);
        break;
      case StockLogReason.deleted:
        writer.writeByte(8);
        break;
      case StockLogReason.restored:
        writer.writeByte(9);
        break;
      case StockLogReason.cleared:
        writer.writeByte(10);
        break;
      case StockLogReason.consumed:
        writer.writeByte(11);
        break;
      case StockLogReason.unknown:
        writer.writeByte(12);
        break;
      case StockLogReason.stockIn:
        writer.writeByte(13);
        break;
      case StockLogReason.stockOut:
        writer.writeByte(14);
        break;
      case StockLogReason.stockAdjustment:
        writer.writeByte(15);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockLogReasonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
