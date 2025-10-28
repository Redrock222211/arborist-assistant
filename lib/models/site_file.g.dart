// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_file.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SiteFileAdapter extends TypeAdapter<SiteFile> {
  @override
  final int typeId = 5;

  @override
  SiteFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteFile(
      id: fields[0] as String,
      siteId: fields[1] as String,
      fileName: fields[2] as String,
      originalName: fields[3] as String,
      filePath: fields[4] as String,
      fileUrl: fields[5] as String,
      fileType: fields[6] as String,
      fileSize: fields[7] as int,
      uploadDate: fields[8] as DateTime,
      uploadedBy: fields[9] as String,
      description: fields[10] as String,
      category: fields[11] as String,
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SiteFile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteId)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.originalName)
      ..writeByte(4)
      ..write(obj.filePath)
      ..writeByte(5)
      ..write(obj.fileUrl)
      ..writeByte(6)
      ..write(obj.fileType)
      ..writeByte(7)
      ..write(obj.fileSize)
      ..writeByte(8)
      ..write(obj.uploadDate)
      ..writeByte(9)
      ..write(obj.uploadedBy)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.category)
      ..writeByte(12)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
