import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/project_model.dart';
import '../controllers/project_tree_controller.dart';

class ProjectDialogs {
  ProjectDialogs._();

  static Future<void> showCreateDialog(
    BuildContext context,
    WidgetRef ref, {
    String? defaultParentId,
  }) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final tagsController = TextEditingController();
    String? selectedParentId = defaultParentId;
    const String selectedIcon = 'folder';

    final projects = ref.read(projectTreeControllerProvider).value?.allProjects ?? [];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Project Directory'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'e.g., Flutter Architecture, API Design',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Purpose of this project repository...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: selectedParentId,
                        decoration: const InputDecoration(
                          labelText: 'Parent Directory (Optional)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('📁 Root Directory (No Parent)'),
                          ),
                          ...projects.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text('📁 ${p.name}'),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => selectedParentId = val),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                          hintText: 'mobile, flutter, state-management',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final tags = tagsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    await ref
                        .read(projectTreeControllerProvider.notifier)
                        .createProject(
                          name: name,
                          description: descController.text.trim(),
                          icon: selectedIcon,
                          parentId: selectedParentId,
                          tags: tags,
                        );

                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Create Project'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final controller = TextEditingController(text: project.name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Project Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != project.name) {
                await ref
                    .read(projectTreeControllerProvider.notifier)
                    .renameProject(project.id, newName);
              }
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  static Future<void> showMoveDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final allProjects =
        ref.read(projectTreeControllerProvider).value?.allProjects ?? [];
    final eligibleProjects =
        allProjects.where((p) => p.id != project.id).toList();

    String? selectedParentId = project.parentId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Move "${project.name}"'),
          content: DropdownButtonFormField<String?>(
            initialValue: selectedParentId,
            decoration: const InputDecoration(labelText: 'Destination Folder'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('📁 Root Directory'),
              ),
              ...eligibleProjects.map(
                (p) => DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text('📁 ${p.name}'),
                ),
              ),
            ],
            onChanged: (val) => setState(() => selectedParentId = val),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(projectTreeControllerProvider.notifier)
                    .moveProject(project.id, selectedParentId);
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}" and all saved responses inside it? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(projectTreeControllerProvider.notifier)
                  .deleteProject(project.id);
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
