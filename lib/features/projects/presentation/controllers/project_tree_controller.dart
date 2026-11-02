import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/projects_repository.dart';
import '../../domain/project_model.dart';
import '../../domain/project_tree_node.dart';

class ProjectTreeState {
  final List<ProjectModel> allProjects;
  final List<ProjectTreeNode> treeNodes;
  final List<ProjectTreeNode> flatVisibleNodes;
  final Set<String> expandedIds;
  final String? selectedProjectId;

  const ProjectTreeState({
    this.allProjects = const [],
    this.treeNodes = const [],
    this.flatVisibleNodes = const [],
    this.expandedIds = const {},
    this.selectedProjectId,
  });

  ProjectTreeState copyWith({
    List<ProjectModel>? allProjects,
    List<ProjectTreeNode>? treeNodes,
    List<ProjectTreeNode>? flatVisibleNodes,
    Set<String>? expandedIds,
    String? selectedProjectId,
    bool clearSelection = false,
  }) {
    return ProjectTreeState(
      allProjects: allProjects ?? this.allProjects,
      treeNodes: treeNodes ?? this.treeNodes,
      flatVisibleNodes: flatVisibleNodes ?? this.flatVisibleNodes,
      expandedIds: expandedIds ?? this.expandedIds,
      selectedProjectId:
          clearSelection ? null : (selectedProjectId ?? this.selectedProjectId),
    );
  }

  ProjectModel? get selectedProject {
    if (selectedProjectId == null) return null;
    return allProjects.cast<ProjectModel?>().firstWhere(
          (p) => p?.id == selectedProjectId,
          orElse: () => null,
        );
  }
}

final projectTreeControllerProvider =
    AsyncNotifierProvider<ProjectTreeController, ProjectTreeState>(
  ProjectTreeController.new,
);

class ProjectTreeController extends AsyncNotifier<ProjectTreeState> {
  StreamSubscription<List<ProjectModel>>? _sub;
  final Set<String> _expandedIds = {};
  String? _selectedProjectId;

  @override
  FutureOr<ProjectTreeState> build() async {
    final user = ref.watch(currentUserProvider);
    final repo = ref.watch(projectsRepositoryProvider);

    _sub?.cancel();

    final completer = Completer<List<ProjectModel>>();

    _sub = repo.watchProjects(user.id).listen(
      (projects) {
        if (!completer.isCompleted) {
          completer.complete(projects);
        } else {
          _updateStateWithProjects(projects);
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

    final initialProjects = await completer.future;

    if (_selectedProjectId == null && initialProjects.isNotEmpty) {
      _selectedProjectId = initialProjects.first.id;
    }

    return _computeState(initialProjects);
  }

  void _updateStateWithProjects(List<ProjectModel> projects) {
    if (_selectedProjectId != null &&
        !projects.any((p) => p.id == _selectedProjectId)) {
      _selectedProjectId = projects.isNotEmpty ? projects.first.id : null;
    }
    state = AsyncValue.data(_computeState(projects));
  }

  ProjectTreeState _computeState(List<ProjectModel> projects) {
    final tree = ProjectTreeNode.buildTree(
      allProjects: projects,
      expandedIds: _expandedIds,
    );
    final flat = ProjectTreeNode.flattenVisibleTree(tree);

    return ProjectTreeState(
      allProjects: projects,
      treeNodes: tree,
      flatVisibleNodes: flat,
      expandedIds: Set.unmodifiable(_expandedIds),
      selectedProjectId: _selectedProjectId,
    );
  }

  void selectProject(String? projectId) {
    _selectedProjectId = projectId;
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(selectedProjectId: projectId));
    }
  }

  void toggleExpand(String projectId) {
    if (_expandedIds.contains(projectId)) {
      _expandedIds.remove(projectId);
    } else {
      _expandedIds.add(projectId);
    }
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(_computeState(current.allProjects));
    }
  }

  Future<void> createProject({
    required String name,
    String description = '',
    String icon = 'folder',
    String? parentId,
    List<String> tags = const [],
  }) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(projectsRepositoryProvider);

    final id = const Uuid().v4();
    final now = DateTime.now();
    final newProject = ProjectModel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
      tags: tags,
    );

    if (parentId != null) {
      _expandedIds.add(parentId);
    }

    _selectedProjectId = id;
    await repo.createProject(user.id, newProject);
  }

  Future<void> renameProject(String projectId, String newName) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(projectsRepositoryProvider);
    final current = state.value;
    if (current == null) return;

    final project = current.allProjects.firstWhere((p) => p.id == projectId);
    final updated = project.copyWith(name: newName, updatedAt: DateTime.now());
    await repo.updateProject(user.id, updated);
  }

  Future<void> moveProject(String projectId, String? newParentId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(projectsRepositoryProvider);
    await repo.moveProject(user.id, projectId, newParentId);
    if (newParentId != null) {
      _expandedIds.add(newParentId);
    }
  }

  Future<void> deleteProject(String projectId) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(projectsRepositoryProvider);
    await repo.deleteProject(user.id, projectId);
    if (_selectedProjectId == projectId) {
      _selectedProjectId = null;
    }
  }
}
