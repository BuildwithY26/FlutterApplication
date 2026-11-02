import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../projects/presentation/widgets/sidebar_project_tree.dart';
import '../../responses/presentation/widgets/create_response_dialog.dart';
import '../../responses/presentation/widgets/markdown_viewer_pane.dart';
import '../../responses/presentation/widgets/response_list_pane.dart';
import '../../search/presentation/command_palette_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final FocusNode _keyboardFocusNode = FocusNode();
  final bool _isSidebarVisible = true;
  final bool _isResponseListVisible = true;

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlOrMeta =
          HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;

      if (isControlOrMeta &&
          event.logicalKey == LogicalKeyboardKey.keyK) {
        CommandPaletteDialog.show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive collapse on smaller displays
    final showSidebar = _isSidebarVisible && screenWidth > 768;
    final showResponseList = _isResponseListVisible && screenWidth > 960;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Row(
          children: [
            // 1. Left Project Tree Sidebar
            if (showSidebar)
              SidebarProjectTree(
                onOpenSearch: () => CommandPaletteDialog.show(context),
                onNewResponse: () => CreateResponseDialog.show(context),
              ),

            // 2. Middle Project Responses List Pane
            if (showResponseList) const ResponseListPane(),

            // 3. Right Markdown Artifact Viewer Pane
            const Expanded(
              child: MarkdownViewerPane(),
            ),
          ],
        ),
      ),
    );
  }
}
