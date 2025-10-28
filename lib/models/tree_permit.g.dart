// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_permit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TreePermitAdapter extends TypeAdapter<TreePermit> {
  @override
  final int typeId = 3;

  @override
  TreePermit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TreePermit(
      id: fields[0] as String,
      siteId: fields[1] as String,
      address: fields[2] as String,
      latitude: fields[3] as double?,
      longitude: fields[4] as double?,
      councilName: fields[5] as String,
      permitStatus: fields[6] as String,
      permitType: fields[7] as String,
      requirements: fields[8] as String,
      notes: fields[9] as String,
      searchDate: fields[10] as DateTime,
      searchMethod: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TreePermit obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteId)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.councilName)
      ..writeByte(6)
      ..write(obj.permitStatus)
      ..writeByte(7)
      ..write(obj.permitType)
      ..writeByte(8)
      ..write(obj.requirements)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.searchDate)
      ..writeByte(11)
      ..write(obj.searchMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreePermitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
