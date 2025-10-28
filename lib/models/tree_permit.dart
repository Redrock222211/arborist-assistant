import 'package:hive/hive.dart';

part 'tree_permit.g.dart';

@HiveType(typeId: 3)
class TreePermit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String siteId;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final double? latitude;

  @HiveField(4)
  final double? longitude;

  @HiveField(5)
  final String councilName;

  @HiveField(6)
  final String permitStatus;

  @HiveField(7)
  final String permitType;

  @HiveField(8)
  final String requirements;

  @HiveField(9)
  final String notes;

  @HiveField(10)
  final DateTime searchDate;

  @HiveField(11)
  final String searchMethod; // 'address' or 'gps'

  TreePermit({
    required this.id,
    required this.siteId,
    required this.address,
    this.latitude,
    this.longitude,
    required this.councilName,
    required this.permitStatus,
    required this.permitType,
    required this.requirements,
    required this.notes,
    required this.searchDate,
    required this.searchMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'councilName': councilName,
      'permitStatus': permitStatus,
      'permitType': permitType,
      'requirements': requirements,
      'notes': notes,
      'searchDate': searchDate.toIso8601String(),
      'searchMethod': searchMethod,
    };
  }

  factory TreePermit.fromMap(Map<String, dynamic> map) {
    return TreePermit(
      id: map['id'],
      siteId: map['siteId'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      councilName: map['councilName'],
      permitStatus: map['permitStatus'],
      permitType: map['permitType'],
      requirements: map['requirements'],
      notes: map['notes'],
      searchDate: DateTime.parse(map['searchDate']),
      searchMethod: map['searchMethod'],
    );
  }
}
