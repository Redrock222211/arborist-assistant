// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branding_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BrandingSettingsAdapter extends TypeAdapter<BrandingSettings> {
  @override
  final int typeId = 2;

  @override
  BrandingSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrandingSettings(
      logoPath: fields[0] as String?,
      scale: fields[1] as String,
      placement: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BrandingSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.logoPath)
      ..writeByte(1)
      ..write(obj.scale)
      ..writeByte(2)
      ..write(obj.placement);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandingSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
