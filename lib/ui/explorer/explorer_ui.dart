import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';
import 'package:pro_coding_studio/logic/tabs/editor_tabs_logic.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart'
    as doc_logic;

class ExplorerUI extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const ExplorerUI({
    Key? key,
    required this.scrollController,
  }) : super(key: key);

  @override
  ConsumerState<ExplorerUI> createState() => _ExplorerUIState();
}

class _ExplorerUIState extends ConsumerState<ExplorerUI> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final docFileHandler = ref.watch(doc_logic.documentFileHandlerProvider);
    final currentDirectoryInfo =
        ref.watch(doc_logic.currentDirectoryInfoProvider);
    final files = ref.watch(doc_logic.filesListInfoProvider);
    final isLoading = ref.watch(doc_logic.explorerLoadingProvider);
    final hasPermission = ref.watch(doc_logic.hasExplorerPermissionProvider);
    final selectedFile = ref.watch(doc_logic.selectedFileInfoProvider);
    final directoryUri = ref.watch(doc_logic.directoryUriProvider);
    final canNavigateBack = ref.watch(doc_logic.canNavigateBackProvider);

    // Build the UI depending on the state
    return WillPopScope(
      // Handle back button press
      onWillPop: () async {
        // If already navigating, don't handle back press
        if (_isNavigating) return false;

        // Set navigating state to show loading indicator
        setState(() {
          _isNavigating = true;
        });

        try {
          // If we can navigate back in our directory history, do so
          if (canNavigateBack) {
            final result = await docFileHandler.handleBackPress();
            return !result;
          }
          // Otherwise, let the system handle the back button
          return true;
        } finally {
          // Reset navigating state
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Explorer header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2128),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explorer',
                      style: TextStyle(
                        color: Color(0xFF64FFDA),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (currentDirectoryInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          currentDirectoryInfo.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Explorer actions
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Open folder button
                    ElevatedButton.icon(
                      onPressed: () async {
                        await docFileHandler.requestDirectoryAccess();
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64FFDA),
                        foregroundColor: Colors.black,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Navigate up button
                    if (directoryUri != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: (_isNavigating || isLoading)
                            ? null
                            : () async {
                                // Set navigating state to show loading indicator
                                setState(() {
                                  _isNavigating = true;
                                });

                                try {
                                  // Check if we can navigate back in history
                                  final canNavigateBack = ref
                                      .read(doc_logic.canNavigateBackProvider);
                                  if (canNavigateBack) {
                                    // Use history-based navigation
                                    await docFileHandler.handleBackPress();
                                  } else {
                                    // Fall back to parent directory navigation if no history
                                    await docFileHandler.navigateUp();
                                  }
                                } finally {
                                  // Reset navigating state
                                  if (mounted) {
                                    setState(() {
                                      _isNavigating = false;
                                    });
                                  }
                                }
                              },
                        color: Colors.white70,
                      ),

                    const Spacer(),

                    // Create new file/folder buttons
                    if (directoryUri != null) ...[
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: () async {
                          // Call refreshCurrentDirectory from DocumentFileHandlerLogic
                          await docFileHandler.refreshCurrentDirectory();
                        },
                        color: const Color(0xFF64FFDA),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder),
                        onPressed: () {
                          _showCreateDialog(context, ref, isFolder: true);
                        },
                        color: const Color(0xFF64FFDA),
                      ),
                      IconButton(
                        icon: const Icon(Icons.note_add),
                        onPressed: () {
                          _showCreateDialog(context, ref);
                        },
                        color: const Color(0xFF64FFDA),
                      ),
                    ],
                  ],
                ),
              ),

              // Loading indicator or no permission message
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
                    ),
                  ),
                )
              else if (!hasPermission)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No folder open',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Open a folder to explore files',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            await docFileHandler.requestDirectoryAccess();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64FFDA),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Open Folder'),
                        ),
                      ],
                    ),
                  ),
                )
              // File list
              else if (files.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: widget.scrollController,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isSelected = selectedFile?.uri == file.uri;

                      final fileIcon = _getFileIcon(file);

                      return ListTile(
                        leading: Icon(
                          fileIcon,
                          color: file.isDirectory
                              ? const Color(0xFF64FFDA)
                              : Colors.white70,
                        ),
                        title: Text(
                          file.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF64FFDA)
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!file.isDirectory)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                color: Colors.white54,
                                onPressed: () async {
                                  final selectedFile =
                                      await docFileHandler.selectFile(file);
                                  if (selectedFile != null) {
                                    final content = await docFileHandler
                                        .readFileContents(selectedFile);

                                    // Store in our state notifier for tab switching
                                    ref
                                        .read(editorStateNotifierProvider
                                            .notifier)
                                        .setFileContent(file.name, content);

                                    // Update editor content for compatibility with the simple state providers
                                    ref
                                        .read(editorContentProvider.notifier)
                                        .state = content;

                                    // Add to tabs using the tabs system
                                    ref
                                        .read(editorTabsProvider.notifier)
                                        .openTab(file.name);

                                    // Also update openFile for compatibility
                                    ref.read(openFileProvider.notifier).state =
                                        file.name;

                                    ref
                                        .read(
                                            hasUnsavedChangesProvider.notifier)
                                        .state = false;
                                    Navigator.pop(
                                        context); // Close the explorer
                                  }
                                },
                              ),
                          ],
                        ),
                        onTap: () async {
                          if (file.isDirectory) {
                            // Navigate into directory
                            await docFileHandler.navigateToDirectory(file);
                          } else {
                            // Select and open the file
                            final selectedFile =
                                await docFileHandler.selectFile(file);
                            if (selectedFile != null) {
                              final content = await docFileHandler
                                  .readFileContents(selectedFile);

                              // Store in our state notifier for tab switching
                              ref
                                  .read(editorStateNotifierProvider.notifier)
                                  .setFileContent(file.name, content);

                              // Update editor content for compatibility
                              ref.read(editorContentProvider.notifier).state =
                                  content;

                              // Add to tabs using the tabs system
                              ref
                                  .read(editorTabsProvider.notifier)
                                  .openTab(file.name);

                              // Also update openFile for compatibility
                              ref.read(openFileProvider.notifier).state =
                                  file.name;

                              ref
                                  .read(hasUnsavedChangesProvider.notifier)
                                  .state = false;
                              Navigator.pop(context); // Close the explorer
                            }
                          }
                        },
                      );
                    },
                  ),
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'This folder is empty',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Loading overlay
          if (_isNavigating || isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23262F),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isNavigating ? 'Navigating...' : 'Loading...',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to determine the icon for a file based on its extension
  IconData _getFileIcon(DocumentFileInfo file) {
    if (file.isDirectory) {
      return Icons.folder;
    }

    final ext = file.extension?.toLowerCase() ?? '';

    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'java':
      case 'kt':
        return Icons.android;
      case 'json':
        return Icons.data_object;
      case 'xml':
      case 'html':
        return Icons.code;
      case 'css':
        return Icons.style;
      case 'js':
        return Icons.javascript;
      case 'md':
        return Icons.description;
      case 'txt':
        return Icons.description;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method to show create file/folder dialog
  void _showCreateDialog(BuildContext context, WidgetRef ref,
      {bool isFolder = false}) {
    final TextEditingController controller = TextEditingController();
    final docFileHandler = ref.read(doc_logic.documentFileHandlerProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        title: Text(
          isFolder ? 'Create New Folder' : 'Create New File',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isFolder ? 'Folder name' : 'File name',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF64FFDA)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF64FFDA), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              if (isFolder) {
                await docFileHandler.createNewFolder(name);
              } else {
                await docFileHandler.createNewFile(name);
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(isFolder ? 'Create Folder' : 'Create File'),
          ),
        ],
      ),
    );
  }
}
