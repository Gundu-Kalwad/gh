// This file will contain the logic for code editing features.
// For now, it's a placeholder for future logic (save, open, etc).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';
import 'package:pro_coding_studio/logic/tabs/editor_tabs_logic.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';

/// Provider for currently open file
/// This is used in the UI to show which file is currently open
final openFileProvider = StateProvider<String?>((ref) => null);

/// Provider for currently open folder
/// Used by file explorer to know which folder to display
final openFolderProvider = StateProvider<String?>((ref) => null);

/// Provider for editor content
/// The actual text being edited in the editor
final editorContentProvider = StateProvider<String>((ref) => '');

/// Provider for tracking unsaved changes
/// Used by UI to show indicators for unsaved work
final hasUnsavedChangesProvider = StateProvider<bool>((ref) => false);

/// Provider to store file contents for quick tab switching
final fileContentsProvider = StateProvider<Map<String, String>>((ref) => {});

// Example of using a StateNotifier for more complex editor logic
class EditorState {
  final String? openFile;
  final String? openFolder;
  final String content;
  final bool hasUnsavedChanges;
  final Map<String, String> fileContents;

  EditorState({
    this.openFile,
    this.openFolder,
    this.content = '',
    this.hasUnsavedChanges = false,
    this.fileContents = const {},
  });

  EditorState copyWith({
    String? openFile,
    String? openFolder,
    String? content,
    bool? hasUnsavedChanges,
    Map<String, String>? fileContents,
  }) {
    return EditorState(
      openFile: openFile ?? this.openFile,
      openFolder: openFolder ?? this.openFolder,
      content: content ?? this.content,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      fileContents: fileContents ?? this.fileContents,
    );
  }
}

/// More advanced state management using StateNotifier for complex state
class EditorStateNotifier extends StateNotifier<EditorState> {
  EditorStateNotifier() : super(EditorState());

  void openFile(String filePath) {
    // Check if we already have content for this file
    final existingContent = state.fileContents[filePath];

    if (existingContent != null) {
      // Use existing content if available
      state = state.copyWith(
        openFile: filePath,
        content: existingContent,
        hasUnsavedChanges: false,
      );
    } else {
      // For new files that don't have content yet, use empty content
      // The actual loading will happen in ExplorerUI
      state = state.copyWith(
        openFile: filePath,
        content: '',
        hasUnsavedChanges: false,
      );
    }
  }

  void updateContent(String content) {
    final currentFile = state.openFile;
    if (currentFile != null) {
      // Store updated content in the file contents map
      final updatedContents = Map<String, String>.from(state.fileContents);
      updatedContents[currentFile] = content;

      state = state.copyWith(
        content: content,
        hasUnsavedChanges: true,
        fileContents: updatedContents,
      );
    } else {
      state = state.copyWith(content: content, hasUnsavedChanges: true);
    }
  }

  void setFileContent(String filePath, String content) {
    // Store file content in the map for future tab switching
    final updatedContents = Map<String, String>.from(state.fileContents);
    updatedContents[filePath] = content;

    state = state.copyWith(
      openFile: filePath,
      content: content,
      fileContents: updatedContents,
      hasUnsavedChanges: false,
    );
  }

  void save() {
    // Save logic here
    final currentFile = state.openFile;
    if (currentFile != null) {
      // Update the saved content in our map
      final updatedContents = Map<String, String>.from(state.fileContents);
      updatedContents[currentFile] = state.content;

      state = state.copyWith(
        hasUnsavedChanges: false,
        fileContents: updatedContents,
      );
    } else {
      state = state.copyWith(hasUnsavedChanges: false);
    }
  }

  void closeFile() {
    state = state.copyWith(
      openFile: null,
      content: '',
      hasUnsavedChanges: false,
    );
  }
}

final editorStateNotifierProvider =
    StateNotifierProvider<EditorStateNotifier, EditorState>(
        (ref) => EditorStateNotifier());

/// Class that provides document API integration for editor operations
class EditorDocumentOperations {
  final WidgetRef _ref;

  EditorDocumentOperations(this._ref);

  /// Create a new file with a dialog prompt
  Future<bool> createNewFile(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);

    // Show dialog to get file name
    final fileName = await _showNameInputDialog(
      context,
      'Create New File',
      'Enter file name:',
      'untitled.dart',
    );

    if (fileName == null || fileName.isEmpty) {
      return false;
    }

    // Create the file using document API
    final newFile = await docHandler.createNewFile(fileName);

    if (newFile != null) {
      // Update editor state with the new file
      _ref.read(openFileProvider.notifier).state = newFile.name;
      _ref.read(editorContentProvider.notifier).state = '';
      _ref.read(hasUnsavedChangesProvider.notifier).state = false;

      // Add to tabs
      _ref.read(editorTabsProvider.notifier).openTab(newFile.name);

      // Update the editor state notifier
      _ref.read(editorStateNotifierProvider.notifier).setFileContent(
            newFile.name,
            '',
          );

      // Select the file in explorer
      _ref.read(selectedFileInfoProvider.notifier).state = newFile;

      return true;
    }

    return false;
  }

  /// Create a new folder with a dialog prompt
  Future<bool> createNewFolder(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);

    // Show dialog to get folder name
    final folderName = await _showNameInputDialog(
      context,
      'Create New Folder',
      'Enter folder name:',
      'New Folder',
    );

    if (folderName == null || folderName.isEmpty) {
      return false;
    }

    // Create the folder using document API
    final newFolder = await docHandler.createNewFolder(folderName);

    if (newFolder != null) {
      // Update the open folder provider
      _ref.read(openFolderProvider.notifier).state = newFolder.name;
      return true;
    }

    return false;
  }

  /// Open a file using document API
  /// This directly opens the system file manager to select a file
  /// regardless of whether a folder is already open
  Future<bool> openFile(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);

    // Directly request to open a file using the system file manager
    final fileInfo = await docHandler.requestOpenFile();

    // If no file was selected, return false
    if (fileInfo == null) {
      return false;
    }

    // Read the file content
    final content = await docHandler.readFileContents(fileInfo);

    // Update editor state
    _ref.read(openFileProvider.notifier).state = fileInfo.name;
    _ref.read(editorContentProvider.notifier).state = content;
    _ref.read(hasUnsavedChangesProvider.notifier).state = false;

    // Add to tabs
    _ref.read(editorTabsProvider.notifier).openTab(fileInfo.name);

    // Update editor state notifier
    _ref.read(editorStateNotifierProvider.notifier).setFileContent(
          fileInfo.name,
          content,
        );

    // Select the file in explorer
    _ref.read(selectedFileInfoProvider.notifier).state = fileInfo;

    return true;
  }

  /// Open a folder using document API
  Future<bool> openFolder(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);

    // Request directory access
    final success = await docHandler.requestDirectoryAccess();

    if (success) {
      // Get the current directory info
      final dirInfo = _ref.read(currentDirectoryInfoProvider);
      if (dirInfo != null) {
        _ref.read(openFolderProvider.notifier).state = dirInfo.name;
      }
      return true;
    }

    return false;
  }

  /// Save the current file using document API
  Future<bool> saveFile(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);
    final editorState = _ref.read(editorStateNotifierProvider);

    // Check if we have a file open
    if (editorState.openFile == null) {
      return await saveFileAs(context);
    }

    // Get the selected file
    final selectedFile = _ref.read(selectedFileInfoProvider);
    if (selectedFile == null || selectedFile.isDirectory) {
      return await saveFileAs(context);
    }

    // Write content to file
    final success = await docHandler.writeToFile(
      selectedFile,
      editorState.content,
    );

    if (success) {
      // Update editor state
      _ref.read(editorStateNotifierProvider.notifier).save();
      _ref.read(hasUnsavedChangesProvider.notifier).state = false;
      return true;
    }

    return false;
  }

  /// Save the current file with a new name
  Future<bool> saveFileAs(BuildContext context) async {
    // Cache all providers and values BEFORE any await that could lead to disposal
    final docHandler = _ref.read(documentFileHandlerProvider);
    final editorState = _ref.read(editorStateNotifierProvider);
    final openFileProviderNotifier = _ref.read(openFileProvider.notifier);
    final hasUnsavedChangesProviderNotifier =
        _ref.read(hasUnsavedChangesProvider.notifier);
    final editorTabsProviderNotifier = _ref.read(editorTabsProvider.notifier);
    final editorStateNotifierProviderNotifier =
        _ref.read(editorStateNotifierProvider.notifier);
    final selectedFileInfoProviderNotifier =
        _ref.read(selectedFileInfoProvider.notifier);

    // Show dialog to get file name
    final fileName = await _showNameInputDialog(
      context,
      'Save As',
      'Enter file name:',
      editorState.openFile ?? 'untitled.dart',
    );

    if (fileName == null || fileName.isEmpty) {
      return false;
    }

    // Create a new file
    final newFile = await docHandler.createNewFile(fileName);

    if (newFile != null) {
      // Write content to the new file
      final success = await docHandler.writeToFile(
        newFile,
        editorState.content,
      );

      if (success) {
        // Only update providers if the context is still mounted
        if (context.mounted) {
          openFileProviderNotifier.state = newFile.name;
          hasUnsavedChangesProviderNotifier.state = false;
          editorTabsProviderNotifier.openTab(newFile.name);
          editorStateNotifierProviderNotifier.setFileContent(
            newFile.name,
            editorState.content,
          );
          selectedFileInfoProviderNotifier.state = newFile;
        }
        return true;
      }
    }

    return false;
  }

  /// Save all open files
  Future<bool> saveAllFiles(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);
    final editorState = _ref.read(editorStateNotifierProvider);
    final tabsState = _ref.read(editorTabsProvider);

    bool allSaved = true;

    // Save the current file first
    if (editorState.openFile != null && editorState.hasUnsavedChanges) {
      final currentFile = _ref.read(selectedFileInfoProvider);
      if (currentFile != null && !currentFile.isDirectory) {
        final success = await docHandler.writeToFile(
          currentFile,
          editorState.content,
        );

        if (!success) {
          allSaved = false;
        }
      }
    }

    // Save all other open files in tabs
    for (final tabName in tabsState.openTabs) {
      // Skip the current file as it's already saved
      if (tabName == editorState.openFile) continue;

      // Get content for this tab
      final content = editorState.fileContents[tabName];
      if (content != null) {
        // Find the file in the explorer
        final files = _ref.read(filesListInfoProvider);
        DocumentFileInfo? fileToSave;
        try {
          fileToSave = files.firstWhere(
            (file) => file.name == tabName,
          );
        } catch (e) {
          // File not found in the current directory
          fileToSave = null;
        }

        if (fileToSave != null) {
          final success = await docHandler.writeToFile(fileToSave, content);
          if (!success) {
            allSaved = false;
          }
        }
      }
    }

    // Update editor state
    if (allSaved) {
      _ref.read(editorStateNotifierProvider.notifier).save();
      _ref.read(hasUnsavedChangesProvider.notifier).state = false;
    }

    return allSaved;
  }

  /// Close the current file
  void closeFile() {
    final openFile = _ref.read(openFileProvider);

    if (openFile != null) {
      // Close the tab
      _ref.read(editorTabsProvider.notifier).closeTabByName(openFile);
    }

    // Reset editor state
    _ref.read(editorStateNotifierProvider.notifier).closeFile();
    _ref.read(openFileProvider.notifier).state = null;
    _ref.read(editorContentProvider.notifier).state = '';
    _ref.read(hasUnsavedChangesProvider.notifier).state = false;
  }

  /// Close the current folder
  void closeFolder() {
    _ref.read(openFolderProvider.notifier).state = null;
    _ref.read(directoryUriProvider.notifier).state = null;
    _ref.read(currentDirectoryInfoProvider.notifier).state = null;
    _ref.read(filesListInfoProvider.notifier).state = [];
    _ref.read(hasExplorerPermissionProvider.notifier).state = false;
  }

  /// Delete the current file
  Future<bool> deleteFile(BuildContext context) async {
    final docHandler = _ref.read(documentFileHandlerProvider);
    final selectedFile = _ref.read(selectedFileInfoProvider);

    if (selectedFile == null || selectedFile.isDirectory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file selected to delete'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    // Show confirmation dialog
    final confirm = await _showConfirmDialog(
      context,
      'Delete File',
      'Are you sure you want to delete ${selectedFile.name}?',
    );

    if (confirm != true) {
      return false;
    }

    // Delete the file using our implemented method
    final success = await docHandler.deleteFile(selectedFile);

    if (success) {
      // Close the file if it's open
      final openFile = _ref.read(openFileProvider);
      if (openFile == selectedFile.name) {
        closeFile();
      }

      // Remove from tabs
      _ref.read(editorTabsProvider.notifier).closeTabByName(selectedFile.name);

      return true;
    }

    return false;
  }

  /// Exit the application
  void exitApplication() {
    // This would typically use Platform-specific exit methods
    if (Platform.isAndroid) {
      // For Android, you might want to minimize the app instead of exiting
      // Implementation would go here
    }
    // For other platforms, you might want to exit the app
    // Implementation would go here
  }

  /// Helper method to show a name input dialog
  Future<String?> _showNameInputDialog(
    BuildContext context,
    String title,
    String label,
    String initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
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
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Helper method to show a confirmation dialog
  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Provider for editor document operations
final editorDocumentOperationsProvider =
    Provider.family<EditorDocumentOperations, WidgetRef>(
  (ref, widgetRef) => EditorDocumentOperations(widgetRef),
);
