import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_converters.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String icon; // Icon name (e.g., 'folder', 'code', 'terminal') or Hex Color
  final String? parentId; // null = root directory
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'folder',
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  bool get isRoot => parentId == null || parentId!.trim().isEmpty;

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? parentId,
    bool clearParentId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProjectModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Project',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'folder',
      parentId: data['parentId'] as String?,
      createdAt: FirestoreConverters.toDateTime(data['createdAt']),
      updatedAt: FirestoreConverters.toDateTime(data['updatedAt']),
      tags: FirestoreConverters.toStringList(data['tags']),
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json, [String? id]) {
    return ProjectModel(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Project',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'folder',
      parentId: json['parentId'] as String?,
      createdAt: FirestoreConverters.toDateTime(json['createdAt']),
      updatedAt: FirestoreConverters.toDateTime(json['updatedAt']),
      tags: FirestoreConverters.toStringList(json['tags']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'parentId': parentId,
      'createdAt': FirestoreConverters.fromDateTime(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'tags': tags,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          icon == other.icon &&
          parentId == other.parentId &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      icon.hashCode ^
      parentId.hashCode ^
      updatedAt.hashCode;
}
