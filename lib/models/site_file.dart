import 'package:hive/hive.dart';

part 'site_file.g.dart';

@HiveType(typeId: 5)
class SiteFile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String siteId;

  @HiveField(2)
  String fileName;

  @HiveField(3)
  String originalName;

  @HiveField(4)
  String filePath;

  @HiveField(5)
  String fileUrl;

  @HiveField(6)
  String fileType;

  @HiveField(7)
  int fileSize;

  @HiveField(8)
  DateTime uploadDate;

  @HiveField(9)
  String uploadedBy;

  @HiveField(10)
  String description;

  @HiveField(11)
  String category;

  @HiveField(12)
  bool isSynced;

  SiteFile({
    required this.id,
    required this.siteId,
    required this.fileName,
    required this.originalName,
    required this.filePath,
    this.fileUrl = '',
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    required this.uploadedBy,
    this.description = '',
    this.category = 'General',
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'fileName': fileName,
      'originalName': originalName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadDate': uploadDate.toIso8601String(),
      'uploadedBy': uploadedBy,
      'description': description,
      'category': category,
      'isSynced': isSynced,
    };
  }

  factory SiteFile.fromMap(Map<String, dynamic> map) {
    return SiteFile(
      id: map['id'],
      siteId: map['siteId'],
      fileName: map['fileName'],
      originalName: map['originalName'],
      filePath: map['filePath'],
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'],
      fileSize: map['fileSize'],
      uploadDate: DateTime.parse(map['uploadDate']),
      uploadedBy: map['uploadedBy'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      isSynced: map['isSynced'] ?? false,
    );
  }

  SiteFile copyWith({
    String? id,
    String? siteId,
    String? fileName,
    String? originalName,
    String? filePath,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    DateTime? uploadDate,
    String? uploadedBy,
    String? description,
    String? category,
    bool? isSynced,
  }) {
    return SiteFile(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      fileName: fileName ?? this.fileName,
      originalName: originalName ?? this.originalName,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      description: description ?? this.description,
      category: category ?? this.category,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
