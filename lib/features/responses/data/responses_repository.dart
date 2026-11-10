import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ai_response_model.dart';

abstract class ResponsesRepository {
  Stream<List<AiResponseModel>> watchResponses(String userId, String projectId);
  Future<List<AiResponseModel>> getPagedResponses(
    String userId,
    String projectId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  });
  Future<void> saveResponse(String userId, String projectId, AiResponseModel response);
  Future<void> updateResponse(String userId, String projectId, AiResponseModel response);
  Future<void> togglePin(String userId, String projectId, String responseId, bool isPinned);
  Future<void> deleteResponse(String userId, String projectId, String responseId);
  Future<void> moveResponse(
    String userId,
    String oldProjectId,
    String newProjectId,
    AiResponseModel response,
  );
  Future<List<AiResponseModel>> searchAllUserResponses(String userId, String searchTerm);
}

final responsesRepositoryProvider = Provider<ResponsesRepository>((ref) {
  if (Firebase.apps.isNotEmpty) {
    return FirestoreResponsesRepository(FirebaseFirestore.instance);
  }
  return InMemoryResponsesRepository();
});

class FirestoreResponsesRepository implements ResponsesRepository {
  final FirebaseFirestore _firestore;

  FirestoreResponsesRepository(this._firestore);

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

  @override
  Stream<List<AiResponseModel>> watchResponses(String userId, String projectId) {
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

  @override
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

  @override
  Future<void> saveResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(response.id);
    await docRef.set(response.toFirestore());
  }

  @override
  Future<void> updateResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(response.id);
    await docRef.update(response.toFirestore());
  }

  @override
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

  @override
  Future<void> deleteResponse(
    String userId,
    String projectId,
    String responseId,
  ) async {
    final docRef = _responsesRef(userId, projectId).doc(responseId);
    await docRef.delete();
  }

  @override
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

  @override
  Future<List<AiResponseModel>> searchAllUserResponses(
    String userId,
    String searchTerm,
  ) async {
    final term = searchTerm.trim().toLowerCase();
    if (term.isEmpty) return [];

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

/// In-memory repository with preloaded sample artifacts and responses.
class InMemoryResponsesRepository implements ResponsesRepository {
  final List<AiResponseModel> _responses = [];
  final _controller = StreamController<List<AiResponseModel>>.broadcast();

  InMemoryResponsesRepository() {
    _seedInitialResponses();
  }

  void _seedInitialResponses() {
    final now = DateTime.now();
    _responses.addAll([
      AiResponseModel(
        id: 'resp-1',
        projectId: 'proj-1',
        title: 'Clean Architecture with Riverpod & Offline Sync',
        content: '''# Production Architecture: Riverpod & Clean Architecture

Clean architecture organizes the application into loosely coupled layers, isolating business logic from external frameworks, APIs, and UI widgets.

### Core Architectural Layers:
1. **Domain Layer**: Pure Dart entities and value objects with no external dependencies.
2. **Data Layer**: Repositories converting raw Firestore documents or HTTP responses into immutable domain models.
3. **Presentation Layer**: Riverpod `AsyncNotifier` state controllers and atomic UI components.

```dart
// Example: Riverpod 3.0 AsyncNotifier Implementation
class ProjectTreeController extends AsyncNotifier<ProjectTreeState> {
  @override
  FutureOr<ProjectTreeState> build() async {
    final repo = ref.watch(projectsRepositoryProvider);
    final projects = await repo.getProjects();
    return ProjectTreeState(allProjects: projects);
  }

  Future<void> createProject(String name) async {
    final repo = ref.read(projectsRepositoryProvider);
    final newProject = ProjectModel(id: Uuid().v4(), name: name);
    await repo.createProject(newProject);
  }
}
```

### Benefits of this Pattern:
- **Instant Testability**: Domain and controllers can be unit tested without Flutter test harnesses.
- **Optimistic UI Updates**: Riverpod emits local updates immediately, reconciling with Firestore in the background.
- **Zero Memory Leaks**: Stream subscriptions are automatically disposed via `ref.onDispose()`.
''',
        modelName: 'Claude 3.5 Sonnet',
        tags: ['architecture', 'riverpod', 'flutter'],
        isPinned: true,
        metadata: {
          'tokens': 1240,
          'prompt': 'Explain clean architecture with Riverpod in Flutter Web & Desktop.',
        },
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      AiResponseModel(
        id: 'resp-2',
        projectId: 'proj-1',
        title: 'Optimized Flutter Web CanvasKit Performance',
        content: '''# Optimizing Flutter Web Performance with CanvasKit

When building desktop-grade web applications in Flutter, smooth 60 FPS rendering is critical.

### Key Optimization Strategies:
- **Const Constructors**: Prevent unnecessary widget rebuild cascades.
- **RepaintBoundary**: Isolate frequently repainting regions (such as animations or highlighters).
- **Virtualized Lists**: Use `ListView.builder` or `SliverList` for large collections.

```dart
// Isolate expensive markdown/code rendering
RepaintBoundary(
  child: MarkdownBody(
    data: content,
    builders: {'pre': CodeBlockBuilder()},
  ),
)
```

| Technique | Memory Impact | Render Latency |
|---|---|---|
| Auto Dispose Providers | Low | Minimal |
| Pre-cached Syntax Highlighters | Moderate | < 16ms |
| Debounced Input Handling | Negligible | Realtime |
''',
        modelName: 'Claude 3.5 Sonnet',
        tags: ['performance', 'web', 'canvaskit'],
        isPinned: false,
        metadata: {'tokens': 860},
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      AiResponseModel(
        id: 'resp-3',
        projectId: 'proj-1-1',
        title: 'AsyncNotifier vs Notifier Comparison Guide',
        content: '''# Riverpod: AsyncNotifier vs Notifier

Understanding when to choose `AsyncNotifier` vs `Notifier` ensures clean asynchronous state handling.

### Guidelines:
- **Use `AsyncNotifier`** when the state originates from an asynchronous source (Firestore, SQLite, REST API, WebSocket).
- **Use `Notifier`** for synchronous local UI state (theme mode, active tab, sidebar expanded toggle).

```dart
// Synchronous Notifier
class ThemeModeNotifier extends Notifier<String> {
  @override
  String build() => 'dark';

  void toggle() => state = state == 'dark' ? 'light' : 'dark';
}
```
''',
        modelName: 'GPT-4o',
        tags: ['riverpod', 'state-management'],
        isPinned: true,
        metadata: {'tokens': 620},
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      AiResponseModel(
        id: 'resp-4',
        projectId: 'proj-2',
        title: 'Firestore Security Rules & Tenant Isolation',
        content: '''# Firestore Security Rules: Strict User Isolation

To guarantee multi-tenant security in Firebase, apply strict ownership checks on all read/write paths:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId}/{document=**} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

> [!IMPORTANT]
> Always pair collection group queries with explicit constraints on the document path to prevent cross-user data leakage.
''',
        modelName: 'Claude 3.7 Sonnet',
        tags: ['firebase', 'security', 'firestore'],
        isPinned: false,
        metadata: {'tokens': 780},
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  void _notify() {
    _controller.add(List.unmodifiable(_responses));
  }

  @override
  Stream<List<AiResponseModel>> watchResponses(String userId, String projectId) async* {
    List<AiResponseModel> getFiltered() {
      final list = _responses.where((r) => r.projectId == projectId).toList();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    }

    yield getFiltered();
    yield* _controller.stream.map((_) => getFiltered());
  }

  @override
  Future<List<AiResponseModel>> getPagedResponses(
    String userId,
    String projectId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final list = _responses.where((r) => r.projectId == projectId).toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list.take(limit).toList();
  }

  @override
  Future<void> saveResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    _responses.add(response);
    _notify();
  }

  @override
  Future<void> updateResponse(
    String userId,
    String projectId,
    AiResponseModel response,
  ) async {
    final idx = _responses.indexWhere((r) => r.id == response.id);
    if (idx != -1) {
      _responses[idx] = response;
      _notify();
    }
  }

  @override
  Future<void> togglePin(
    String userId,
    String projectId,
    String responseId,
    bool isPinned,
  ) async {
    final idx = _responses.indexWhere((r) => r.id == responseId);
    if (idx != -1) {
      _responses[idx] = _responses[idx].copyWith(
        isPinned: isPinned,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> deleteResponse(
    String userId,
    String projectId,
    String responseId,
  ) async {
    _responses.removeWhere((r) => r.id == responseId);
    _notify();
  }

  @override
  Future<void> moveResponse(
    String userId,
    String oldProjectId,
    String newProjectId,
    AiResponseModel response,
  ) async {
    final idx = _responses.indexWhere((r) => r.id == response.id);
    if (idx != -1) {
      _responses[idx] = _responses[idx].copyWith(
        projectId: newProjectId,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<List<AiResponseModel>> searchAllUserResponses(
    String userId,
    String searchTerm,
  ) async {
    final term = searchTerm.trim().toLowerCase();
    if (term.isEmpty) return [];

    return _responses.where((item) {
      final titleMatch = item.title.toLowerCase().contains(term);
      final contentMatch = item.content.toLowerCase().contains(term);
      final tagMatch = item.tags.any((t) => t.toLowerCase().contains(term));
      final modelMatch = item.modelName.toLowerCase().contains(term);
      return titleMatch || contentMatch || tagMatch || modelMatch;
    }).toList();
  }
}
