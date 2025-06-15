import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';

/// Provider for the DocumentFileHandler
final documentFileHandlerProvider = Provider<DocumentFileHandlerLogic>((ref) {
  return DocumentFileHandlerLogic(ref);
});

/// Provider for the current directory URI
final directoryUriProvider = StateProvider<String?>((ref) => null);

/// Provider for the current directory's DocumentFileInfo
final currentDirectoryInfoProvider =
    StateProvider<DocumentFileInfo?>((ref) => null);

/// Provider for files list using DocumentFileInfo
final filesListInfoProvider =
    StateProvider<List<DocumentFileInfo>>((ref) => []);

/// Provider for the selected DocumentFileInfo
final selectedFileInfoProvider =
    StateProvider<DocumentFileInfo?>((ref) => null);

/// Provider for directory navigation history
final directoryHistoryProvider =
    StateNotifierProvider<DirectoryHistoryNotifier, List<String>>(
        (ref) => DirectoryHistoryNotifier());

/// Provider to check if we can navigate back
final canNavigateBackProvider = Provider<bool>((ref) {
  final history = ref.watch(directoryHistoryProvider);
  return history.length >
      1; // We can go back if we have more than one item in history
});

/// Notifier for directory navigation history
class DirectoryHistoryNotifier extends StateNotifier<List<String>> {
  DirectoryHistoryNotifier() : super([]);

  /// Add a directory to history
  void addDirectory(String uri) {
    // If the last directory is the same as the new one, don't add it
    if (state.isNotEmpty && state.last == uri) return;

    // Add the new directory to history
    state = [...state, uri];
  }

  /// Go back to previous directory
  String? goBack() {
    if (state.length <= 1) return null;

    // Remove current directory and return the previous one
    final newState = List<String>.from(state);
    newState.removeLast(); // Remove current directory
    final previousDirectory = newState.last; // Get the previous directory

    state = newState; // Update state
    return previousDirectory;
  }

  /// Clear history
  void clear() {
    state = [];
  }
}

/// Logic class to handle document file operations
class DocumentFileHandlerLogic {
  final ProviderRef _ref;

  DocumentFileHandlerLogic(this._ref);

  /// Handle back button press
  /// Returns true if back navigation was handled, false otherwise
  Future<bool> handleBackPress() async {
    // Check if we can navigate back
    final historyNotifier = _ref.read(directoryHistoryProvider.notifier);
    final previousUri = historyNotifier.goBack();

    if (previousUri == null) {
      return false; // Can't go back, let the system handle it
    }

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      // Update the URI
      _ref.read(directoryUriProvider.notifier).state = previousUri;

      // Load files from previous directory
      await _loadFilesFromDirectory(previousUri);

      // Get directory info for the previous URI
      try {
        // Get the list of files in the parent directory
        final parentFiles = await DocumentFileHandler.listFiles(previousUri);

        // Find the directory info in the parent's file list
        for (final file in parentFiles) {
          if (file.uri == previousUri && file.isDirectory) {
            _ref.read(currentDirectoryInfoProvider.notifier).state = file;
            break;
          }
        }
      } catch (e) {
        print('Error getting directory info: $e');
      }

      return true; // We handled the back press
    } catch (e) {
      print('Error handling back press: $e');
      return false;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Request access to a directory
  Future<bool> requestDirectoryAccess() async {
    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      final directoryUri = await DocumentFileHandler.openDocumentTree();
      if (directoryUri == null) {
        _ref.read(explorerLoadingProvider.notifier).state = false;
        return false;
      }

      // Update the directoryUriProvider
      _ref.read(directoryUriProvider.notifier).state = directoryUri;
      _ref.read(hasExplorerPermissionProvider.notifier).state = true;

      // Clear history and add this as the first directory
      _ref.read(directoryHistoryProvider.notifier).clear();
      _ref.read(directoryHistoryProvider.notifier).addDirectory(directoryUri);

      // Load files from this directory
      await _loadFilesFromDirectory(directoryUri);

      return true;
    } catch (e) {
      print('Error requesting directory access: $e');
      return false;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Restore previous directory access
  Future<bool> restorePreviousAccess() async {
    final currentUri = _ref.read(directoryUriProvider);
    if (currentUri == null) return false;

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      // Try to load files from previously accessed directory
      await _loadFilesFromDirectory(currentUri);
      return true;
    } catch (e) {
      print('Error restoring previous access: $e');
      return false;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Navigate up to parent directory
  Future<bool> navigateUp() async {
    final currentUri = _ref.read(directoryUriProvider);
    if (currentUri == null) return false;

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      final parentUri = await DocumentFileHandler.getParentUri(currentUri);
      if (parentUri == null || parentUri == currentUri) {
        return false; // Already at root or no parent
      }

      // Update the URI
      _ref.read(directoryUriProvider.notifier).state = parentUri;

      // Add to navigation history
      _ref.read(directoryHistoryProvider.notifier).addDirectory(parentUri);

      // Load files from parent
      await _loadFilesFromDirectory(parentUri);

      return true;
    } catch (e) {
      print('Error navigating up: $e');
      return false;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Navigate to a directory
  Future<void> navigateToDirectory(DocumentFileInfo directory) async {
    if (!directory.isDirectory) return;

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      // Update current directory provider
      _ref.read(currentDirectoryInfoProvider.notifier).state = directory;

      // Update directory URI
      _ref.read(directoryUriProvider.notifier).state = directory.uri;

      // Add to navigation history
      _ref.read(directoryHistoryProvider.notifier).addDirectory(directory.uri);

      // Load files from this directory
      await _loadFilesFromDirectory(directory.uri);
    } catch (e) {
      print('Error navigating to directory: $e');
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Select a file
  Future<DocumentFileInfo?> selectFile(DocumentFileInfo file) async {
    if (file.isDirectory) return null;

    _ref.read(selectedFileInfoProvider.notifier).state = file;
    return file;
  }

  /// Read file contents
  Future<String> readFileContents(DocumentFileInfo file) async {
    try {
      return await DocumentFileHandler.readFileContent(file.uri);
    } catch (e) {
      print('Error reading file: $e');
      return '';
    }
  }

  /// Write to file
  Future<bool> writeToFile(DocumentFileInfo file, String contents) async {
    try {
      return await DocumentFileHandler.writeFileContent(file.uri, contents);
    } catch (e) {
      print('Error writing to file: $e');
      return false;
    }
  }

  /// Create a new file
  Future<DocumentFileInfo?> createNewFile(String fileName) async {
    final directoryUri = _ref.read(directoryUriProvider);
    if (directoryUri == null) return null;

    try {
      // Determine mime type based on extension
      String mimeType = "text/plain";
      if (fileName.endsWith('.dart')) {
        mimeType = "application/dart";
      } else if (fileName.endsWith('.json')) {
        mimeType = "application/json";
      } else if (fileName.endsWith('.html')) {
        mimeType = "text/html";
      } else if (fileName.endsWith('.css')) {
        mimeType = "text/css";
      } else if (fileName.endsWith('.js')) {
        mimeType = "application/javascript";
      }

      // Create the file
      final newFile = await DocumentFileHandler.createFile(
        directoryUri,
        fileName,
        mimeType: mimeType,
      );

      // Refresh file list
      if (newFile != null) {
        await _loadFilesFromDirectory(directoryUri);
      }

      return newFile;
    } catch (e) {
      print('Error creating file: $e');
      return null;
    }
  }

  /// Request to open a file directly using the system file picker
  /// This allows selecting a file without first opening a directory
  Future<DocumentFileInfo?> requestOpenFile() async {
    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      // Open a file using the system file picker
      final fileInfo = await DocumentFileHandler.openDocument();

      if (fileInfo != null) {
        // Update the selected file provider
        _ref.read(selectedFileInfoProvider.notifier).state = fileInfo;

        // If the file is in a directory, try to update that directory's info
        final fileUri = fileInfo.uri;
        if (fileUri.contains('/')) {
          final lastSlash = fileUri.lastIndexOf('/');
          if (lastSlash > 0) {
            final directoryUri = fileUri.substring(0, lastSlash);
            _ref.read(directoryUriProvider.notifier).state = directoryUri;

            // Try to load files from this directory in the background
            _loadFilesFromDirectory(directoryUri);
          }
        }
      }

      return fileInfo;
    } catch (e) {
      print('Error requesting to open file: $e');
      return null;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Create a new folder
  Future<DocumentFileInfo?> createNewFolder(String folderName) async {
    final directoryUri = _ref.read(directoryUriProvider);
    if (directoryUri == null) return null;

    try {
      // Create the folder
      final newFolder = await DocumentFileHandler.createDirectory(
        directoryUri,
        folderName,
      );

      // Refresh file list
      if (newFolder != null) {
        await _loadFilesFromDirectory(directoryUri);
      }

      return newFolder;
    } catch (e) {
      print('Error creating folder: $e');
      return null;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(DocumentFileInfo file) async {
    if (file.isDirectory) {
      print('Cannot delete directory using deleteFile method: ${file.name}');
      return false;
    }

    try {
      print('Attempting to delete file: ${file.name} (URI: ${file.uri})');

      // Delete the file
      final success = await DocumentFileHandler.deleteFile(file.uri);

      print('Delete result for ${file.name}: $success');

      // Refresh the file list if deletion was successful
      if (success) {
        final directoryUri = _ref.read(directoryUriProvider);
        if (directoryUri != null) {
          print('Refreshing file list after deletion');
          await _loadFilesFromDirectory(directoryUri);

          // Remove the file from selected file provider if it was selected
          final selectedFile = _ref.read(selectedFileInfoProvider);
          if (selectedFile != null && selectedFile.uri == file.uri) {
            _ref.read(selectedFileInfoProvider.notifier).state = null;
            print('Cleared selected file reference');
          }
        }
      } else {
        print('File deletion failed: ${file.name}');
      }

      return success;
    } catch (e) {
      print('Error deleting file ${file.name}: $e');
      return false;
    }
  }

  /// Public method to refresh the file list in the current directory
  Future<void> refreshCurrentDirectory() async {
    final directoryUri = _ref.read(directoryUriProvider);
    if (directoryUri != null) {
      await _loadFilesFromDirectory(directoryUri);
    }
  }

  /// Load files from directory
  Future<void> _loadFilesFromDirectory(String directoryUri) async {
    try {
      final files = await DocumentFileHandler.listFiles(directoryUri);

      // Sort directories first, then files alphabetically
      files.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      // Update provider
      _ref.read(filesListInfoProvider.notifier).state = files;
    } catch (e) {
      print('Error loading files: $e');
      _ref.read(filesListInfoProvider.notifier).state = [];
    }
  }
}

/// Provider for loading state
final explorerLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for permission state
final hasExplorerPermissionProvider = StateProvider<bool>((ref) => false);
