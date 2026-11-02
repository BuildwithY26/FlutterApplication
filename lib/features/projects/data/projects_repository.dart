import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_model.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(FirebaseFirestore.instance);
});

class ProjectsRepository {
  final FirebaseFirestore _firestore;

  ProjectsRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _projectsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('projects');
  }

  /// Streams real-time updates for all user projects with Firestore offline cache backing.
  Stream<List<ProjectModel>> watchProjects(String userId) {
    return _projectsRef(userId)
        .orderBy('name')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    });
  }

  /// One-time fetch with cache-first strategy.
  Future<List<ProjectModel>> getProjects(String userId) async {
    try {
      final snapshot = await _projectsRef(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      // Offline fallback
      final cached = await _projectsRef(userId).get(
        const GetOptions(source: Source.cache),
      );
      return cached.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    }
  }

  Future<void> createProject(String userId, ProjectModel project) async {
    final docRef = _projectsRef(userId).doc(project.id);
    await docRef.set(project.toFirestore());
  }

  Future<void> updateProject(String userId, ProjectModel project) async {
    final docRef = _projectsRef(userId).doc(project.id);
    await docRef.update(project.toFirestore());
  }

  Future<void> moveProject(
    String userId,
    String projectId,
    String? newParentId,
  ) async {
    // Avoid setting self as parent
    if (projectId == newParentId) return;
    final docRef = _projectsRef(userId).doc(projectId);
    await docRef.update({
      'parentId': newParentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProject(String userId, String projectId) async {
    final batch = _firestore.batch();
    final projectDoc = _projectsRef(userId).doc(projectId);

    // Delete sub-responses
    final responses = await projectDoc.collection('responses').get();
    for (final doc in responses.docs) {
      batch.delete(doc.reference);
    }

    // Reparent immediate child projects to root or current parent
    final childProjects = await _projectsRef(userId)
        .where('parentId', isEqualTo: projectId)
        .get();
    for (final child in childProjects.docs) {
      batch.update(child.reference, {'parentId': null});
    }

    batch.delete(projectDoc);
    await batch.commit();
  }
}
