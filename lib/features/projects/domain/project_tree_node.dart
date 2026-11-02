import 'project_model.dart';

/// Represents a hierarchical tree node for nested project directories.
class ProjectTreeNode {
  final ProjectModel project;
  final List<ProjectTreeNode> children;
  final int depth;
  final bool isExpanded;

  const ProjectTreeNode({
    required this.project,
    this.children = const [],
    this.depth = 0,
    this.isExpanded = false,
  });

  bool get hasChildren => children.isNotEmpty;

  ProjectTreeNode copyWith({
    ProjectModel? project,
    List<ProjectTreeNode>? children,
    int depth = 0,
    bool? isExpanded,
  }) {
    return ProjectTreeNode(
      project: project ?? this.project,
      children: children ?? this.children,
      depth: depth,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  /// Builds a tree structure from a flat list of ProjectModels
  static List<ProjectTreeNode> buildTree({
    required List<ProjectModel> allProjects,
    required Set<String> expandedIds,
    String? rootParentId,
    int depth = 0,
  }) {
    final Map<String?, List<ProjectModel>> parentMap = {};
    for (final project in allProjects) {
      final pId = (project.parentId == null || project.parentId!.trim().isEmpty)
          ? null
          : project.parentId;
      parentMap.putIfAbsent(pId, () => []).add(project);
    }

    List<ProjectTreeNode> buildLevel(String? parentId, int currentDepth) {
      final items = parentMap[parentId] ?? [];
      // Sort alphabetically
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return items.map((p) {
        final isExpanded = expandedIds.contains(p.id);
        final children = buildLevel(p.id, currentDepth + 1);
        return ProjectTreeNode(
          project: p,
          children: children,
          depth: currentDepth,
          isExpanded: isExpanded,
        );
      }).toList();
    }

    return buildLevel(rootParentId, depth);
  }

  /// Flattens the visible tree based on current expansion state for ListView rendering.
  static List<ProjectTreeNode> flattenVisibleTree(List<ProjectTreeNode> nodes) {
    final List<ProjectTreeNode> visible = [];
    void traverse(ProjectTreeNode node) {
      visible.add(node);
      if (node.isExpanded) {
        for (final child in node.children) {
          traverse(child);
        }
      }
    }

    for (final root in nodes) {
      traverse(root);
    }
    return visible;
  }
}
