import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../projects/presentation/controllers/project_tree_controller.dart';
import '../../domain/ai_response_model.dart';
import '../controllers/responses_controller.dart';
import 'create_response_dialog.dart';

class ResponseListPane extends ConsumerWidget {
  const ResponseListPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final treeState = ref.watch(projectTreeControllerProvider).value;
    final activeProject = treeState?.selectedProject;
    final responsesAsync = ref.watch(filteredProjectResponsesProvider);
    final selectedId = ref.watch(selectedResponseIdProvider);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header: Project title + count + add response
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activeProject?.name ?? 'Select a Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        activeProject?.description.isNotEmpty == true
                            ? activeProject!.description
                            : 'All saved AI artifacts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'New Response',
                  onPressed: activeProject != null
                      ? () => CreateResponseDialog.show(context)
                      : null,
                ),
              ],
            ),
          ),

          // Search Filter within project
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filter project responses...',
                prefixIcon: const Icon(Icons.filter_list, size: 16),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: ref.watch(responseSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        onPressed: () {
                          ref
                              .read(responseSearchQueryProvider.notifier)
                              .clear();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(responseSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),

          // Responses List
          Expanded(
            child: responsesAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ),
              ),
              data: (responses) {
                if (responses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 32,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No responses yet',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first AI prompt/response artifact here.',
                            textAlign: TextAlign.center,
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
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: responses.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  itemBuilder: (context, index) {
                    final item = responses[index];
                    final isSelected = item.id == selectedId;

                    return _ResponseTile(
                      response: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        ref
                            .read(selectedResponseIdProvider.notifier)
                            .setSelected(item.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseTile extends StatelessWidget {
  final AiResponseModel response;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ResponseTile({
    required this.response,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark
        ? AppColors.accentClaude.withValues(alpha: 0.16)
        : AppColors.accentClaude.withValues(alpha: 0.08);

    final cleanSnippet = response.content
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'[`*_~]'), '')
        .trim();

    final dateStr = DateFormat('MMM d').format(response.updatedAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? selectedColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Title & Pin
            Row(
              children: [
                if (response.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.push_pin,
                      size: 13,
                      color: AppColors.accentTerracotta,
                    ),
                  ),
                Expanded(
                  child: Text(
                    response.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Content snippet
            Text(
              cleanSnippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),

            // Footer info: Model tag
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkElevated
                        : AppColors.lightElevated,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    response.modelName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),
                if (response.tags.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '#${response.tags.first}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
