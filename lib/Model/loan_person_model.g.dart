// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_person_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanPersonAdapter extends TypeAdapter<LoanPerson> {
  @override
  final int typeId = 2;

  @override
  LoanPerson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanPerson(
      name: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      quantity: fields[3] as double,
      totalAmount: fields[4] as double,
      date: fields[5] as DateTime,
      isPaid: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LoanPerson obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.isPaid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanPersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
