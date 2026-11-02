import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/responses_repository.dart';
import '../../domain/ai_response_model.dart';
import '../../../projects/presentation/controllers/project_tree_controller.dart';

class SelectedResponseIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSelected(String? id) => state = id;
}

final selectedResponseIdProvider =
    NotifierProvider<SelectedResponseIdNotifier, String?>(
  SelectedResponseIdNotifier.new,
);

class ResponseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final responseSearchQueryProvider =
    NotifierProvider<ResponseSearchQueryNotifier, String>(
  ResponseSearchQueryNotifier.new,
);

class SelectedTagFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setTag(String? tag) => state = tag;
}

final selectedTagFilterProvider =
    NotifierProvider<SelectedTagFilterNotifier, String?>(
  SelectedTagFilterNotifier.new,
);

final projectResponsesControllerProvider = AsyncNotifierProvider<
    ProjectResponsesController, List<AiResponseModel>>(
  ProjectResponsesController.new,
);

class ProjectResponsesController
    extends AsyncNotifier<List<AiResponseModel>> {
  StreamSubscription<List<AiResponseModel>>? _sub;

  @override
  FutureOr<List<AiResponseModel>> build() async {
    final user = ref.watch(currentUserProvider);
    final repo = ref.watch(responsesRepositoryProvider);
    final treeState = ref.watch(projectTreeControllerProvider).value;
    final projectId = treeState?.selectedProjectId;

    _sub?.cancel();

    if (projectId == null || projectId.isEmpty) {
      return [];
    }

    final completer = Completer<List<AiResponseModel>>();

    _sub = repo.watchResponses(user.id, projectId).listen(
      (items) {
        if (!completer.isCompleted) {
          completer.complete(items);
        } else {
          state = AsyncValue.data(items);
          _syncSelectedResponse(items);
        }
      },
      onError: (err, stack) {
        if (!completer.isCompleted) {
          completer.completeError(err, stack);
        } else {
          state = AsyncValue.error(err, stack);
        }
      },
    );

    ref.onDispose(() {
      _sub?.cancel();
    });

    final items = await completer.future;
    _syncSelectedResponse(items);
    return items;
  }

  void _syncSelectedResponse(List<AiResponseModel> items) {
    final currentSelectedId = ref.read(selectedResponseIdProvider);
    if (items.isEmpty) {
      ref.read(selectedResponseIdProvider.notifier).setSelected(null);
    } else if (currentSelectedId == null ||
        !items.any((r) => r.id == currentSelectedId)) {
      ref.read(selectedResponseIdProvider.notifier).setSelected(items.first.id);
    }
  }

  Future<AiResponseModel> createResponse({
    required String title,
    required String content,
    String modelName = 'Claude 3.5 Sonnet',
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final treeState = ref.read(projectTreeControllerProvider).value;
    final projectId = treeState?.selectedProjectId;

    if (projectId == null) {
      throw Exception('Cannot create response without an active project selected.');
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final newResponse = AiResponseModel(
      id: id,
      projectId: projectId,
      title: title.isEmpty ? 'New AI Response' : title,
      content: content,
      modelName: modelName,
      tags: tags,
      isPinned: false,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );

    await repo.saveResponse(user.id, projectId, newResponse);
    ref.read(selectedResponseIdProvider.notifier).setSelected(id);
    return newResponse;
  }

  Future<void> updateTitle(String responseId, String newTitle) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final items = state.value ?? [];
    final current = items.cast<AiResponseModel?>().firstWhere(
          (r) => r?.id == responseId,
          orElse: () => null,
        );
    if (current == null) return;

    final updated = current.copyWith(
      title: newTitle.trim().isEmpty ? 'Untitled Response' : newTitle,
      updatedAt: DateTime.now(),
    );
    await repo.updateResponse(user.id, current.projectId, updated);
  }

  Future<void> updateContent(String responseId, String newContent) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final items = state.value ?? [];
    final current = items.cast<AiResponseModel?>().firstWhere(
          (r) => r?.id == responseId,
          orElse: () => null,
        );
    if (current == null) return;

    final updated = current.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
    await repo.updateResponse(user.id, current.projectId, updated);
  }

  Future<void> togglePin(String responseId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final items = state.value ?? [];
    final current = items.cast<AiResponseModel?>().firstWhere(
          (r) => r?.id == responseId,
          orElse: () => null,
        );
    if (current == null) return;

    await repo.togglePin(
      user.id,
      current.projectId,
      responseId,
      !current.isPinned,
    );
  }

  Future<void> deleteResponse(String responseId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final items = state.value ?? [];
    final current = items.cast<AiResponseModel?>().firstWhere(
          (r) => r?.id == responseId,
          orElse: () => null,
        );
    if (current == null) return;

    await repo.deleteResponse(user.id, current.projectId, responseId);

    if (ref.read(selectedResponseIdProvider) == responseId) {
      final remaining = items.where((r) => r.id != responseId).toList();
      ref
          .read(selectedResponseIdProvider.notifier)
          .setSelected(remaining.isNotEmpty ? remaining.first.id : null);
    }
  }

  Future<void> moveResponse(String responseId, String targetProjectId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(responsesRepositoryProvider);
    final items = state.value ?? [];
    final current = items.cast<AiResponseModel?>().firstWhere(
          (r) => r?.id == responseId,
          orElse: () => null,
        );
    if (current == null) return;

    await repo.moveResponse(user.id, current.projectId, targetProjectId, current);
  }
}

final filteredProjectResponsesProvider =
    Provider<AsyncValue<List<AiResponseModel>>>((ref) {
  final responsesAsync = ref.watch(projectResponsesControllerProvider);
  final searchQuery = ref.watch(responseSearchQueryProvider).trim().toLowerCase();
  final selectedTag = ref.watch(selectedTagFilterProvider);

  return responsesAsync.whenData((items) {
    return items.where((item) {
      final matchesQuery = searchQuery.isEmpty ||
          item.title.toLowerCase().contains(searchQuery) ||
          item.content.toLowerCase().contains(searchQuery);

      final matchesTag =
          selectedTag == null || item.tags.contains(selectedTag);

      return matchesQuery && matchesTag;
    }).toList();
  });
});

final activeAiResponseProvider = Provider<AiResponseModel?>((ref) {
  final selectedId = ref.watch(selectedResponseIdProvider);
  if (selectedId == null) return null;

  final responses = ref.watch(projectResponsesControllerProvider).value;
  if (responses == null) return null;

  return responses.cast<AiResponseModel?>().firstWhere(
        (r) => r?.id == selectedId,
        orElse: () => null,
      );
});
