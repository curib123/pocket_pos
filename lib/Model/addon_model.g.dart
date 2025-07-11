// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addon_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AddonAdapter extends TypeAdapter<Addon> {
  @override
  final int typeId = 2;

  @override
  Addon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Addon(
      addonId: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      isRequired: fields[3] as bool,
      maxQuantity: fields[4] as int,
      appliesTo: (fields[5] as List?)?.cast<String>(),
      isDeleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Addon obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.addonId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.isRequired)
      ..writeByte(4)
      ..write(obj.maxQuantity)
      ..writeByte(5)
      ..write(obj.appliesTo)
      ..writeByte(6)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
