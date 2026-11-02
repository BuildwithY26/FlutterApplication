import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/project_tree_node.dart';
import '../controllers/project_tree_controller.dart';
import 'project_dialogs.dart';

class SidebarProjectTree extends ConsumerWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onNewResponse;

  const SidebarProjectTree({
    super.key,
    required this.onOpenSearch,
    required this.onNewResponse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final treeAsync = ref.watch(projectTreeControllerProvider);
    final user = ref.watch(currentUserProvider);

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Workspace / User Profile Header
          _buildWorkspaceHeader(context, ref, user, isDark),

          // 2. Quick Action Bar (Search Cmd+K & New Project / New Response)
          _buildQuickActionBar(context, ref, isDark),

          const Divider(height: 1),

          // 3. Project Directory Tree Area
          Expanded(
            child: treeAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load projects: $err',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              data: (treeState) {
                final nodes = treeState.flatVisibleNodes;
                if (nodes.isEmpty) {
                  return _buildEmptyState(context, ref);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: nodes.length,
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    final isSelected =
                        node.project.id == treeState.selectedProjectId;
                    return _ProjectTreeNodeTile(
                      key: ValueKey(node.project.id),
                      node: node,
                      isSelected: isSelected,
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 4. Footer: Theme Toggle & Offline/Storage Indicator
          _buildFooter(context, ref, isDark),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader(
    BuildContext context,
    WidgetRef ref,
    user,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentClaude, AppColors.accentTerracotta],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'AI Knowledge Workspace',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Switch Workspace',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Search Bar (Cmd/Ctrl + K)
          InkWell(
            onTap: onOpenSearch,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search knowledge...',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      '⌘K',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action Buttons: New Project & New Response
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ProjectDialogs.showCreateDialog(context, ref),
                  icon: const Icon(Icons.create_new_folder_outlined, size: 15),
                  label: const Text('Folder', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNewResponse,
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('Response', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.accentClaude,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 40,
              color: AppColors.darkTextMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No projects yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a project directory to organize your AI responses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ProjectDialogs.showCreateDialog(context, ref),
              icon: const Icon(Icons.add, size: 15),
              label: const Text('New Project', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentClaude,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Offline / Sync indicator
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.accentEmerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Synced • Offline Ready',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),

          // Theme Switcher Button
          IconButton(
            icon: Icon(
              themeMode == 'dark' ? Icons.dark_mode : Icons.light_mode,
              size: 17,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
        ],
      ),
    );
  }
}

/// Expandable tree node item with nested indentation & context menu
class _ProjectTreeNodeTile extends ConsumerStatefulWidget {
  final ProjectTreeNode node;
  final bool isSelected;

  const _ProjectTreeNodeTile({
    super.key,
    required this.node,
    required this.isSelected,
  });

  @override
  ConsumerState<_ProjectTreeNodeTile> createState() =>
      _ProjectTreeNodeTileState();
}

class _ProjectTreeNodeTileState extends ConsumerState<_ProjectTreeNodeTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final project = widget.node.project;
    final hasChildren = widget.node.hasChildren;
    final depth = widget.node.depth;

    final selectedBg = isDark
        ? AppColors.accentClaude.withValues(alpha: 0.18)
        : AppColors.accentClaude.withValues(alpha: 0.12);

    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          ref
              .read(projectTreeControllerProvider.notifier)
              .selectProject(project.id);
        },
        onSecondaryTapUp: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          padding: EdgeInsets.only(
            left: 6.0 + (depth * 14.0),
            right: 6.0,
            top: 4.0,
            bottom: 4.0,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? selectedBg
                : (_isHovered ? hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.accentClaude.withValues(alpha: 0.4),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Expand/Collapse Chevron
              if (hasChildren)
                InkWell(
                  onTap: () {
                    ref
                        .read(projectTreeControllerProvider.notifier)
                        .toggleExpand(project.id);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      widget.node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(width: 20),

              // Folder / Project Icon
              Icon(
                widget.node.isExpanded
                    ? Icons.folder_open_rounded
                    : Icons.folder_rounded,
                size: 16,
                color: widget.isSelected
                    ? AppColors.accentClaude
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 8),

              // Project Name
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: widget.isSelected
                        ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                ),
              ),

              // 3-dots Context Menu Button (visible on hover or active)
              if (_isHovered || widget.isSelected)
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 14,
                  onPressed: () {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final offset = renderBox.localToGlobal(Offset.zero);
                    _showContextMenu(
                      context,
                      Offset(offset.dx + renderBox.size.width - 20, offset.dy + 20),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      // Tap to select project
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final project = widget.node.project;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'add_sub',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.create_new_folder_outlined, size: 16),
              SizedBox(width: 8),
              Text('Add Sub-folder', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Rename', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'move',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.drive_file_move_outlined, size: 16),
              SizedBox(width: 8),
              Text('Move to Folder...', style: TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        const PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(fontSize: 12.5, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'add_sub':
          ProjectDialogs.showCreateDialog(
            context,
            ref,
            defaultParentId: project.id,
          );
          break;
        case 'rename':
          ProjectDialogs.showRenameDialog(context, ref, project);
          break;
        case 'move':
          ProjectDialogs.showMoveDialog(context, ref, project);
          break;
        case 'delete':
          ProjectDialogs.showDeleteConfirmDialog(context, ref, project);
          break;
      }
    });
  }
}
