import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user.g.dart';

@HiveType(typeId: 5)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String role; // 'admin', 'arborist', 'viewer'

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? lastLoginAt;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final List<String> permissions;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'arborist',
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.permissions = const [],
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission) || role == 'admin';
  }

  bool canEditSites() => hasPermission('edit_sites');
  bool canDeleteSites() => hasPermission('delete_sites');
  bool canEditTrees() => hasPermission('edit_trees');
  bool canDeleteTrees() => hasPermission('delete_trees');
  bool canExportData() => hasPermission('export_data');
  bool canManageUsers() => hasPermission('manage_users');

  /// Convert User to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  /// Create User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: data['id'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'arborist',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null 
          ? (data['lastLoginAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      permissions: List<String>.from(data['permissions'] ?? []),
    );
  }
}
