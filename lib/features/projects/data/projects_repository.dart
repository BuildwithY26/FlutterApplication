import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_model.dart';

abstract class ProjectsRepository {
  Stream<List<ProjectModel>> watchProjects(String userId);
  Future<List<ProjectModel>> getProjects(String userId);
  Future<void> createProject(String userId, ProjectModel project);
  Future<void> updateProject(String userId, ProjectModel project);
  Future<void> moveProject(String userId, String projectId, String? newParentId);
  Future<void> deleteProject(String userId, String projectId);
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreProjectsRepository(FirebaseFirestore.instance);
  }
  return InMemoryProjectsRepository();
});

class FirestoreProjectsRepository implements ProjectsRepository {
  final FirebaseFirestore _firestore;

  FirestoreProjectsRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _projectsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('projects');
  }

  @override
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

  @override
  Future<List<ProjectModel>> getProjects(String userId) async {
    try {
      final snapshot = await _projectsRef(userId).get(
        const GetOptions(source: Source.serverAndCache),
      );
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      final cached = await _projectsRef(userId).get(
        const GetOptions(source: Source.cache),
      );
      return cached.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    }
  }

  @override
  Future<void> createProject(String userId, ProjectModel project) async {
    final docRef = _projectsRef(userId).doc(project.id);
    await docRef.set(project.toFirestore());
  }

  @override
  Future<void> updateProject(String userId, ProjectModel project) async {
    final docRef = _projectsRef(userId).doc(project.id);
    await docRef.update(project.toFirestore());
  }

  @override
  Future<void> moveProject(
    String userId,
    String projectId,
    String? newParentId,
  ) async {
    if (projectId == newParentId) return;
    final docRef = _projectsRef(userId).doc(projectId);
    await docRef.update({
      'parentId': newParentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteProject(String userId, String projectId) async {
    final batch = _firestore.batch();
    final projectDoc = _projectsRef(userId).doc(projectId);

    final responses = await projectDoc.collection('responses').get();
    for (final doc in responses.docs) {
      batch.delete(doc.reference);
    }

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

/// In-memory repository with preloaded seed projects for instant testing and offline use.
class InMemoryProjectsRepository implements ProjectsRepository {
  final List<ProjectModel> _projects = [];
  final _controller = StreamController<List<ProjectModel>>.broadcast();

  InMemoryProjectsRepository() {
    _seedInitialData();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _projects.addAll([
      ProjectModel(
        id: 'proj-1',
        name: 'Flutter Architecture',
        description: 'Clean Architecture, Riverpod & Offline patterns',
        icon: 'folder',
        parentId: null,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        tags: ['flutter', 'architecture', 'riverpod'],
      ),
      ProjectModel(
        id: 'proj-1-1',
        name: 'State Management',
        description: 'Riverpod 2.x & 3.x AsyncNotifier implementations',
        icon: 'folder',
        parentId: 'proj-1',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        tags: ['riverpod', 'async-notifier'],
      ),
      ProjectModel(
        id: 'proj-1-2',
        name: 'UI Design System',
        description: 'Claude-like UI components and Markdown renderer',
        icon: 'folder',
        parentId: 'proj-1',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        tags: ['ui', 'theming', 'markdown'],
      ),
      ProjectModel(
        id: 'proj-2',
        name: 'Backend & Cloud Functions',
        description: 'Firebase Firestore, Security Rules & Auth APIs',
        icon: 'folder',
        parentId: null,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
        tags: ['firebase', 'firestore', 'security'],
      ),
      ProjectModel(
        id: 'proj-3',
        name: 'AI Prompt Engineering',
        description: 'System prompts, reasoning frameworks & templates',
        icon: 'folder',
        parentId: null,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
        tags: ['prompts', 'claude', 'deepseek'],
      ),
    ]);
  }

  void _notify() {
    _controller.add(List.unmodifiable(_projects));
  }

  @override
  Stream<List<ProjectModel>> watchProjects(String userId) async* {
    yield List.unmodifiable(_projects);
    yield* _controller.stream;
  }

  @override
  Future<List<ProjectModel>> getProjects(String userId) async {
    return List.unmodifiable(_projects);
  }

  @override
  Future<void> createProject(String userId, ProjectModel project) async {
    _projects.add(project);
    _notify();
  }

  @override
  Future<void> updateProject(String userId, ProjectModel project) async {
    final idx = _projects.indexWhere((p) => p.id == project.id);
    if (idx != -1) {
      _projects[idx] = project;
      _notify();
    }
  }

  @override
  Future<void> moveProject(String userId, String projectId, String? newParentId) async {
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      _projects[idx] = _projects[idx].copyWith(
        parentId: newParentId,
        clearParentId: newParentId == null,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteProject(String userId, String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    for (int i = 0; i < _projects.length; i++) {
      if (_projects[i].parentId == projectId) {
        _projects[i] = _projects[i].copyWith(clearParentId: true);
      }
    }
    _notify();
  }
}
