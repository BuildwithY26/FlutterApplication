import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/debouncer.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../projects/domain/project_model.dart';
import '../../projects/presentation/controllers/project_tree_controller.dart';
import '../../responses/data/responses_repository.dart';
import '../../responses/domain/ai_response_model.dart';
import '../../responses/presentation/controllers/responses_controller.dart';

class CommandPaletteDialog extends ConsumerStatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => const CommandPaletteDialog(),
    );
  }

  @override
  ConsumerState<CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 250));
  bool _isLoading = false;
  List<ProjectModel> _matchingProjects = [];
  List<AiResponseModel> _matchingResponses = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matchingProjects = [];
        _matchingResponses = [];
        _isLoading = false;
      });
      return;
    }

    _debouncer.run(() async {
      setState(() => _isLoading = true);

      final user = ref.read(currentUserProvider);
      final allProjects =
          ref.read(projectTreeControllerProvider).value?.allProjects ?? [];
      final responsesRepo = ref.read(responsesRepositoryProvider);

      // Search projects in memory
      final projects = allProjects
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.description.toLowerCase().contains(query.toLowerCase()) ||
              p.tags.any((t) => t.toLowerCase().contains(query.toLowerCase())))
          .toList();

      // Search all responses
      final responses =
          await responsesRepo.searchAllUserResponses(user.id, query);

      if (mounted) {
        setState(() {
          _matchingProjects = projects;
          _matchingResponses = responses;
          _isLoading = false;
        });
      }
    });
  }

  void _selectProject(ProjectModel project) {
    ref
        .read(projectTreeControllerProvider.notifier)
        .selectProject(project.id);
    Navigator.of(context).pop();
  }

  void _selectResponse(AiResponseModel response) {
    ref
        .read(projectTreeControllerProvider.notifier)
        .selectProject(response.projectId);
    ref
        .read(selectedResponseIdProvider.notifier)
        .setSelected(response.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 620,
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Search projects, tags, response contents...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkElevated
                              : AppColors.lightElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ESC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Results Area
              Flexible(
                child: _searchController.text.trim().isEmpty
                    ? _buildHints(isDark)
                    : _buildSearchResults(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHints(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK SHORTCUTS & NAVIGATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          _buildHintRow('Search by project name', 'Type "Flutter" or "Backend"'),
          _buildHintRow('Search by tag', 'Type "#architecture" or "#firebase"'),
          _buildHintRow('Search code inside responses', 'Type function names, sql queries'),
        ],
      ),
    );
  }

  Widget _buildHintRow(String title, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          Text(
            hint,
            style: const TextStyle(fontSize: 11.5, color: AppColors.darkTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_matchingProjects.isEmpty && _matchingResponses.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No matching projects or responses found.',
            style: TextStyle(color: AppColors.darkTextMuted),
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_matchingProjects.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'PROJECTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          ..._matchingProjects.map(
            (p) => ListTile(
              dense: true,
              leading: const Icon(Icons.folder_outlined, size: 18),
              title: Text(p.name, style: const TextStyle(fontSize: 13.5)),
              subtitle: p.description.isNotEmpty
                  ? Text(p.description, maxLines: 1)
                  : null,
              onTap: () => _selectProject(p),
            ),
          ),
          const Divider(height: 12),
        ],
        if (_matchingResponses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'AI RESPONSES & ARTIFACTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          ..._matchingResponses.map(
            (r) => ListTile(
              dense: true,
              leading: const Icon(Icons.article_outlined, size: 18),
              title: Text(r.title, style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(
                r.content.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(r.modelName, style: const TextStyle(fontSize: 10)),
              ),
              onTap: () => _selectResponse(r),
            ),
          ),
        ],
      ],
    );
  }
}
