// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteAdapter extends TypeAdapter<Site> {
  @override
  final int typeId = 1;

  @override
  Site read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Site(
      id: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      notes: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      syncStatus: fields[5] as String,
      latitude: fields[6] as double?,
      longitude: fields[7] as double?,
      vicPlanData: (fields[8] as Map?)?.cast<String, dynamic>(),
      reportType: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Site obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.syncStatus)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.vicPlanData)
      ..writeByte(9)
      ..write(obj.reportType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
