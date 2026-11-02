import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_converters.dart';

class AiResponseModel {
  final String id;
  final String projectId;
  final String title;
  final String content;
  final String modelName;
  final List<String> tags;
  final bool isPinned;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiResponseModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.content,
    this.modelName = 'Claude 3.5 Sonnet',
    this.tags = const [],
    this.isPinned = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  int get tokenCount => (metadata['tokens'] as num?)?.toInt() ?? 0;
  String? get promptText => metadata['prompt'] as String?;
  String? get systemPrompt => metadata['systemPrompt'] as String?;
  List<String> get sourceUrls =>
      FirestoreConverters.toStringList(metadata['sourceUrls']);

  AiResponseModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? content,
    String? modelName,
    List<String>? tags,
    bool? isPinned,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiResponseModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      content: content ?? this.content,
      modelName: modelName ?? this.modelName,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AiResponseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? fallbackProjectId,
  }) {
    final data = doc.data() ?? {};
    return AiResponseModel(
      id: doc.id,
      projectId: data['projectId'] as String? ?? fallbackProjectId ?? '',
      title: data['title'] as String? ?? 'Untitled Response',
      content: data['content'] as String? ?? '',
      modelName: data['modelName'] as String? ?? 'Claude 3.5 Sonnet',
      tags: FirestoreConverters.toStringList(data['tags']),
      isPinned: data['isPinned'] as bool? ?? false,
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: FirestoreConverters.toDateTime(data['createdAt']),
      updatedAt: FirestoreConverters.toDateTime(data['updatedAt']),
    );
  }

  factory AiResponseModel.fromJson(Map<String, dynamic> json, [String? id]) {
    return AiResponseModel(
      id: id ?? json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Response',
      content: json['content'] as String? ?? '',
      modelName: json['modelName'] as String? ?? 'Claude 3.5 Sonnet',
      tags: FirestoreConverters.toStringList(json['tags']),
      isPinned: json['isPinned'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: FirestoreConverters.toDateTime(json['createdAt']),
      updatedAt: FirestoreConverters.toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'content': content,
      'modelName': modelName,
      'tags': tags,
      'isPinned': isPinned,
      'metadata': metadata,
      'createdAt': FirestoreConverters.fromDateTime(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'content': content,
      'modelName': modelName,
      'tags': tags,
      'isPinned': isPinned,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiResponseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          projectId == other.projectId &&
          title == other.title &&
          content == other.content &&
          modelName == other.modelName &&
          isPinned == other.isPinned &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      projectId.hashCode ^
      title.hashCode ^
      content.hashCode ^
      modelName.hashCode ^
      isPinned.hashCode ^
      updatedAt.hashCode;
}
