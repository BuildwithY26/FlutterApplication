import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../projects/domain/project_model.dart';
import '../../../projects/presentation/controllers/project_tree_controller.dart';
import '../../domain/ai_response_model.dart';
import '../controllers/responses_controller.dart';
import 'code_block_builder.dart';

class MarkdownViewerPane extends ConsumerStatefulWidget {
  const MarkdownViewerPane({super.key});

  @override
  ConsumerState<MarkdownViewerPane> createState() => _MarkdownViewerPaneState();
}

class _MarkdownViewerPaneState extends ConsumerState<MarkdownViewerPane> {
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _saveTitle(String responseId) {
    setState(() => _isEditingTitle = false);
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty) {
      ref
          .read(projectResponsesControllerProvider.notifier)
          .updateTitle(responseId, newTitle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeResponse = ref.watch(activeAiResponseProvider);
    final treeState = ref.watch(projectTreeControllerProvider).value;
    final activeProject = treeState?.selectedProject;

    if (activeResponse == null) {
      return _buildEmptyState(context, activeProject, isDark);
    }

    if (!_isEditingTitle && _titleController.text != activeResponse.title) {
      _titleController.text = activeResponse.title;
    }

    // Build breadcrumb items
    final breadcrumbs = _buildBreadcrumbList(treeState, activeResponse);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Breadcrumbs Bar
          _buildBreadcrumbsBar(breadcrumbs, isDark),

          const Divider(height: 1),

          // 2. Content Header & Action Toolbar
          _buildContentHeader(context, activeResponse, isDark),

          const Divider(height: 1),

          // 3. Scrollable Rich Markdown Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: SelectionArea(
                    child: MarkdownBody(
                      data: activeResponse.content,
                      selectable: false, // Handled by SelectionArea for smooth copy
                      builders: {
                        'pre': CodeBlockBuilder(isDark: isDark),
                      },
                      styleSheet: _buildMarkdownStyleSheet(theme, isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildBreadcrumbList(
    ProjectTreeState? treeState,
    AiResponseModel response,
  ) {
    final List<String> crumbs = ['Projects'];
    if (treeState == null) return crumbs;

    // Trace parent hierarchy
    final Map<String, ProjectModel> projectMap = {
      for (final p in treeState.allProjects) p.id: p
    };

    final List<String> hierarchy = [];
    String? currentId = response.projectId;

    while (currentId != null && projectMap.containsKey(currentId)) {
      final p = projectMap[currentId]!;
      hierarchy.insert(0, p.name);
      currentId = p.parentId;
    }

    crumbs.addAll(hierarchy);
    crumbs.add(response.title);
    return crumbs;
  }

  Widget _buildBreadcrumbsBar(List<String> breadcrumbs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
      child: Row(
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            Text(
              breadcrumbs[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == breadcrumbs.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: i == breadcrumbs.length - 1
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentHeader(
    BuildContext context,
    AiResponseModel response,
    bool isDark,
  ) {
    final formattedDate =
        DateFormat('MMM d, y • h:mm a').format(response.updatedAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Inline Edit + Actions Toolbar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pin Icon if pinned
              if (response.isPinned)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.push_pin,
                    size: 18,
                    color: AppColors.accentTerracotta,
                  ),
                ),

              // Title Editable or Label
              Expanded(
                child: _isEditingTitle
                    ? TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onSubmitted: (_) => _saveTitle(response.id),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() => _isEditingTitle = true);
                          _titleFocusNode.requestFocus();
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  response.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Action Toolbar
              _buildActionToolbar(context, response, isDark),
            ],
          ),

          const SizedBox(height: 12),

          // Metadata Badges (Model, Date, Tags, Tokens)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Model Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentClaude.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.accentClaude.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppColors.accentClaude,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      response.modelName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentClaude,
                      ),
                    ),
                  ],
                ),
              ),

              // Date
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),

              // Token Count if present
              if (response.tokenCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkElevated
                        : AppColors.lightElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${response.tokenCount} tokens',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),

              // Tags
              ...response.tags.map(
                (tag) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkElevated
                        : AppColors.lightElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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

  Widget _buildActionToolbar(
    BuildContext context,
    AiResponseModel response,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy Markdown Action
        IconButton(
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          tooltip: 'Copy Markdown',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: response.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Markdown copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        // Pin Toggle Action
        IconButton(
          icon: Icon(
            response.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 18,
            color: response.isPinned ? AppColors.accentTerracotta : null,
          ),
          tooltip: response.isPinned ? 'Unpin' : 'Pin to top',
          onPressed: () {
            ref
                .read(projectResponsesControllerProvider.notifier)
                .togglePin(response.id);
          },
        ),

        // Export Dialog Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.download_outlined, size: 18),
          tooltip: 'Export Artifact',
          onSelected: (format) => _handleExport(context, response, format),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'markdown',
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Export as .md'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'json',
              child: Row(
                children: [
                  Icon(Icons.data_object_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Export as JSON'),
                ],
              ),
            ),
          ],
        ),

        // Delete Response Action
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Delete Response',
          onPressed: () => _confirmDelete(context, response),
        ),
      ],
    );
  }

  void _handleExport(
    BuildContext context,
    AiResponseModel response,
    String format,
  ) {
    String output = '';
    if (format == 'markdown') {
      output = '''# ${response.title}
*Model: ${response.modelName}*
*Date: ${response.createdAt.toIso8601String()}*
*Tags: ${response.tags.join(', ')}*

---

${response.content}''';
    } else {
      output = const JsonEncoder.withIndent('  ').convert(response.toJson());
    }

    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported $format copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AiResponseModel response) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Response?'),
        content: Text('Are you sure you want to delete "${response.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref
                  .read(projectResponsesControllerProvider.notifier)
                  .deleteResponse(response.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ProjectModel? project,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 28,
                color: AppColors.accentClaude,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              project != null
                  ? 'No Response Selected in "${project.name}"'
                  : 'Select or Create a Project',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Select an AI response from the project pane or create a new response.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme, bool isDark) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return MarkdownStyleSheet(
      p: GoogleFonts.inter(
        fontSize: 15,
        height: 1.7,
        color: textColor,
      ),
      h1: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      h2: GoogleFonts.inter(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.3,
        height: 1.35,
      ),
      h3: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h4: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 13,
        backgroundColor:
            isDark ? AppColors.darkElevated : AppColors.lightElevated,
        color: AppColors.accentTerracotta,
      ),
      blockquote: GoogleFonts.inter(
        fontSize: 14.5,
        fontStyle: FontStyle.italic,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border: Border(
          left: BorderSide(
            color: AppColors.accentClaude.withValues(alpha: 0.8),
            width: 3.5,
          ),
        ),
      ),
      tableBody: GoogleFonts.inter(fontSize: 13.5, color: textColor),
      tableHead: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      tableBorder: TableBorder.all(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      listBullet: GoogleFonts.inter(fontSize: 14, color: textColor),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
    );
  }
}
