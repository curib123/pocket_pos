// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BatchAdapter extends TypeAdapter<Batch> {
  @override
  final int typeId = 1;

  @override
  Batch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Batch(
      quantity: fields[0] as double,
      kiloQuantity: fields[1] as double,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Batch obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.quantity)
      ..writeByte(1)
      ..write(obj.kiloQuantity)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
