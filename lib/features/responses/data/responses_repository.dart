import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ai_response_model.dart';

final responsesRepositoryProvider = Provider<ResponsesRepository>((ref) {
  return ResponsesRepository(FirebaseFirestore.instance);
});

class ResponsesRepository {
  final FirebaseFirestore _firestore;

  ResponsesRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _responsesRef(
    String userId,
    String projectId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .collection('responses');
  }

  /// Streams responses for a given project ordered by pinned first, then updatedAt descending.
  Stream<List<AiResponseModel>> watchResponses(
    String userId,
    String projectId,
  ) {
    return _responsesRef(userId, projectId)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AiResponseModel.fromFirestore(doc, fallbackProjectId: projectId))
          .toList();
    });
  }

  /// Paginated query for large project archives with cursor support.
  Future<List<AiResponseModel>> getPagedResponses(
    String userId,
    String projectId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _responsesRef(userId, projectId)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((doc) => AiResponseModel.fromFirestore(doc, fallbackProjectId: projectId))
        .toList();
  }

  Future<void> saveResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(response.id);
    await docRef.set(response.toFirestore());
  }

  Future<void> updateResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(response.id);
    await docRef.update(response.toFirestore());
  }

  Future<void> togglePin(
    String userId,
    String projectId,
    String responseId,
    bool isPinned,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(responseId);
    await docRef.update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResponse(
    String userId,
    String projectId,
    String responseId,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(responseId);
    await docRef.delete();
  }

  Future<void> moveResponse(
    String userId,
    String oldProjectId,
    String newProjectId,
    AiResponseModel response,
  ) async {
    if (oldProjectId == newProjectId) return;
    final batch = _firestore.batch();

    final oldRef = _responsesRef(userId, oldProjectId).doc(response.id);
    final newRef = _responsesRef(userId, newProjectId).doc(response.id);

    final updatedModel = response.copyWith(projectId: newProjectId);
    batch.delete(oldRef);
    batch.set(newRef, updatedModel.toFirestore());

    await batch.commit();
  }

  /// Global search across all user responses using Collection Group query.
  Future<List<AiResponseModel>> searchAllUserResponses(
    String userId,
    String searchTerm,
  ) async {
    final term = searchTerm.trim().toLowerCase();
    if (term.isEmpty) return [];

    // Query collectionGroup 'responses'
    final snapshot = await _firestore.collectionGroup('responses').get();
    final allUserResponses = snapshot.docs
        .where((doc) => doc.reference.path.contains('/users/$userId/'))
        .map((doc) => AiResponseModel.fromFirestore(doc))
        .toList();

    return allUserResponses.where((item) {
      final titleMatch = item.title.toLowerCase().contains(term);
      final contentMatch = item.content.toLowerCase().contains(term);
      final tagMatch = item.tags.any((t) => t.toLowerCase().contains(term));
      final modelMatch = item.modelName.toLowerCase().contains(term);
      return titleMatch || contentMatch || tagMatch || modelMatch;
    }).toList();
  }
}
