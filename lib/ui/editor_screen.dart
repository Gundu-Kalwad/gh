import 'package:flutter/material.dart';
import 'toolbar/editor_toolbar.dart';
import 'text_field.dart/editor_textfield.dart';
import 'package:pro_coding_studio/ui/tabs/editor_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';
import 'package:pro_coding_studio/logic/explorer/explorer_logic.dart';
import 'package:pro_coding_studio/logic/tabs/editor_tabs_logic.dart';
import 'package:pro_coding_studio/ui/explorer/explorer_ui.dart';
import 'package:pro_coding_studio/ui/github/github_drawer.dart';
import 'package:pro_coding_studio/ui/github/github_upload_indicator.dart';
import 'package:pro_coding_studio/ui/binary_viewer/binary_file_viewer.dart';
import 'package:pro_coding_studio/logic/binary_file_logic.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';

/// Main editor screen that serves as the container for all editor UI components.
class EditorScreen extends ConsumerWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the state from our providers
    final editorState = ref.watch(editorStateNotifierProvider);
    final tabsState = ref.watch(editorTabsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: EditorToolbar(
        onExplorerPressed: () {
          // Attempt to restore previous directory access when opening explorer
          final explorerLogic = ref.read(explorerLogicProvider);
          explorerLogic.restorePreviousAccess();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF23262F),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            builder: (context) {
              double lastOpenPercent = 0.75;
              double minPercent = 0.15;
              double maxPercent = 0.95;
              return StatefulBuilder(
                builder: (context, setModalState) {
                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      final size = notification.extent;
                      if (size <= 0.15) {
                        Navigator.of(context).maybePop();
                        return true;
                      }
                      if (size >= 0.9 && maxPercent != 0.9) {
                        setModalState(() {
                          maxPercent = 0.9;
                        });
                      }
                      if (size > 0.15 && size < 0.9) {
                        lastOpenPercent = size;
                      }
                      return false;
                    },
                    child: DraggableScrollableSheet(
                      initialChildSize: lastOpenPercent,
                      minChildSize: minPercent,
                      maxChildSize: maxPercent,
                      expand: false,
                      builder: (context, scrollController) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF23262F),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        // Use the ExplorerUI component instead of placeholder text
                        child: ExplorerUI(scrollController: scrollController),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      endDrawer: const GitHubDrawer(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Use the updated EditorTabs with dynamic tabs
              EditorTabs(
                onTabSelected: (index) {
                  final tabName = tabsState.openTabs[index];
                  // Update tab selection in all providers
                  ref.read(editorTabsProvider.notifier).openTab(tabName);
                  ref.read(openFileProvider.notifier).state = tabName;

                  // Example of using the more complex StateNotifierProvider
                  ref
                      .read(editorStateNotifierProvider.notifier)
                      .openFile(tabName);
                },
                onTabClose: (index) {
                  final tabName = tabsState.openTabs[index];
                  final isCurrentTab = tabName == tabsState.currentTab;

                  // Close the tab
                  ref.read(editorTabsProvider.notifier).closeTab(index);

                  // If closing the current tab, reset state
                  if (isCurrentTab) {
                    // Get the new current tab (if any)
                    final newState = ref.read(editorTabsProvider);
                    ref.read(openFileProvider.notifier).state =
                        newState.currentTab;
                    ref.read(hasUnsavedChangesProvider.notifier).state = false;

                    // Example with StateNotifierProvider
                    if (newState.currentTab != null) {
                      ref
                          .read(editorStateNotifierProvider.notifier)
                          .openFile(newState.currentTab!);
                    } else {
                      ref
                          .read(editorStateNotifierProvider.notifier)
                          .closeFile();
                    }
                  }
                },
              ),
              Expanded(child: _buildEditorContent(ref)),
            ],
          ),
          // Add the GitHub upload indicator
          const GitHubUploadIndicator(),
        ],
      ),
    );
  }

  /// Builds the appropriate editor content based on file type
  Widget _buildEditorContent(WidgetRef ref) {
    final selectedFileInfo = ref.watch(selectedFileInfoProvider);
    // If no file is selected, show the regular text editor (empty)
    if (selectedFileInfo == null) {
      return EditorTextField(key: EditorToolbar.editorTextFieldKey);
    }
    // Check if the selected file is a binary file
    final isBinary = ref.watch(isBinaryFileProvider(selectedFileInfo));
    if (isBinary) {
      // Show binary file viewer for binary files
      return BinaryFileViewer(file: selectedFileInfo);
    } else {
      // Show text editor for text files
      return EditorTextField(key: EditorToolbar.editorTextFieldKey);
    }
  }
}
