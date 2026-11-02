import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/responses_controller.dart';
import '../../../projects/presentation/controllers/project_tree_controller.dart';

class CreateResponseDialog extends ConsumerStatefulWidget {
  const CreateResponseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CreateResponseDialog(),
    );
  }

  @override
  ConsumerState<CreateResponseDialog> createState() =>
      _CreateResponseDialogState();
}

class _CreateResponseDialogState extends ConsumerState<CreateResponseDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedModel = 'Claude 3.5 Sonnet';

  final List<String> _models = [
    'Claude 3.5 Sonnet',
    'Claude 3.7 Sonnet',
    'Claude 3.5 Haiku',
    'GPT-4o',
    'Gemini 1.5 Pro',
    'DeepSeek R1',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeState = ref.watch(projectTreeControllerProvider).value;
    final activeProject = treeState?.selectedProject;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_comment_outlined,
              size: 20, color: AppColors.accentClaude),
          const SizedBox(width: 8),
          Text(
            activeProject != null
                ? 'Save AI Response to "${activeProject.name}"'
                : 'Save AI Response',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Response Title *',
                  hintText: 'e.g., Clean Architecture & Riverpod Notifier Implementation',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedModel,
                      decoration: const InputDecoration(
                        labelText: 'Model Used',
                      ),
                      items: _models
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedModel = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        hintText: 'flutter, riverpod, architecture',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'AI Response Content (Markdown) *',
                  hintText: 'Paste Markdown or code artifacts here...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentClaude,
          ),
          onPressed: () async {
            final title = _titleController.text.trim();
            final content = _contentController.text.trim();
            if (content.isEmpty) return;

            final tags = _tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            await ref
                .read(projectResponsesControllerProvider.notifier)
                .createResponse(
                  title: title.isEmpty ? 'Untitled Response' : title,
                  content: content,
                  modelName: _selectedModel,
                  tags: tags,
                );

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save Artifact'),
        ),
      ],
    );
  }
}
