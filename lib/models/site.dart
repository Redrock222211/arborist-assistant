import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'site.g.dart';

@HiveType(typeId: 1)
class Site {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String address;
  @HiveField(3)
  final String notes;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final String syncStatus;
  @HiveField(6)
  final double? latitude;
  @HiveField(7)
  final double? longitude;
  @HiveField(8)
  final Map<String, dynamic>? vicPlanData;

  Site({
    required this.id,
    required this.name,
    required this.address,
    this.notes = '',
    DateTime? createdAt,
    this.syncStatus = 'local',
    this.latitude,
    this.longitude,
    this.vicPlanData,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus,
      'latitude': latitude,
      'longitude': longitude,
      'vicPlanData': vicPlanData,
    };
  }

  factory Site.fromMap(Map<String, dynamic> map) {
    return Site(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      syncStatus: map['syncStatus'] ?? 'local',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      vicPlanData: map['vicPlanData'],
    );
  }

  /// Convert Site to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'syncStatus': syncStatus,
      'latitude': latitude,
      'longitude': longitude,
      'vicPlanData': vicPlanData,
    };
  }

  /// Create Site from Firestore document
  factory Site.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Site(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      syncStatus: data['syncStatus'] ?? 'local',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      vicPlanData: data['vicPlanData'],
    );
  }
}
