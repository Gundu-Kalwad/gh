import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../github_auth_logic/github_login_token.dart' show storage;

/// Provider for the current directory being explored
final currentDirectoryProvider = StateProvider<Directory?>((ref) => null);

/// Provider for the current directory path
final directoryPathProvider = StateProvider<String?>((ref) => null);

/// Provider for the list of files in the current directory
final filesListProvider = StateProvider<List<FileSystemEntity>>((ref) => []);

/// Provider for the currently selected file
final selectedFileProvider = StateProvider<FileSystemEntity?>((ref) => null);

/// Provider to track if explorer is loading files
final explorerLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider to track if we have permission to the folder
final hasExplorerPermissionProvider = StateProvider<bool>((ref) => false);

/// Provider to track recent directories
final recentDirectoriesProvider = StateProvider<List<String>>((ref) => []);

/// Class that handles all explorer logic operations
class ExplorerLogic {
  final ProviderRef _ref;

  ExplorerLogic(this._ref);

  /// Try to restore previous directory access
  Future<bool> restorePreviousAccess() async {
    try {
      final directoryPath = await storage.read(key: 'last_directory_path');

      if (directoryPath == null) {
        return false;
      }

      // Check if the directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return false;
      }

      // Update providers
      _ref.read(currentDirectoryProvider.notifier).state = directory;
      _ref.read(directoryPathProvider.notifier).state = directoryPath;
      _ref.read(hasExplorerPermissionProvider.notifier).state = true;

      // Load files
      await _loadFilesFromDirectory(directoryPath);

      return true;
    } catch (e) {
      debugPrint('Error restoring previous access: $e');
      return false;
    }
  }

  /// Navigate to a directory
  Future<void> navigateToDirectory(FileSystemEntity directory) async {
    if (directory is! Directory) return;

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      final directoryPath = directory.path;

      // Update providers
      _ref.read(directoryPathProvider.notifier).state = directoryPath;
      _ref.read(currentDirectoryProvider.notifier).state = directory;

      // Load files from this directory
      await _loadFilesFromDirectory(directoryPath);

      // Save for persistence
      await storage.write(key: 'last_directory_path', value: directoryPath);

      // Add to recent directories
      await _addToRecentDirectories(directoryPath);
    } catch (e) {
      debugPrint('Error navigating to directory: $e');
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Navigate to parent directory
  Future<bool> navigateUp() async {
    // Get the current directory path
    final directoryPath = _ref.read(directoryPathProvider);
    if (directoryPath == null) return false;

    _ref.read(explorerLoadingProvider.notifier).state = true;

    try {
      // Get parent path
      final directory = Directory(directoryPath);
      final parentDirectory = directory.parent;
      final parentPath = parentDirectory.path;

      if (parentPath == directoryPath) {
        return false; // Already at root
      }

      // Update providers
      _ref.read(directoryPathProvider.notifier).state = parentPath;
      _ref.read(currentDirectoryProvider.notifier).state = parentDirectory;

      // Load files from parent
      await _loadFilesFromDirectory(parentPath);

      // Save for persistence
      await storage.write(key: 'last_directory_path', value: parentPath);

      return true;
    } catch (e) {
      debugPrint('Error navigating up: $e');
      return false;
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }

  /// Select a file
  Future<FileSystemEntity?> selectFile(FileSystemEntity file) async {
    if (file is Directory) return null;

    _ref.read(selectedFileProvider.notifier).state = file;
    return file;
  }

  /// Create a new file in current directory
  Future<File?> createNewFile(String fileName) async {
    final directoryPath = _ref.read(directoryPathProvider);
    if (directoryPath == null) return null;

    try {
      // Make sure file has proper extension
      String fileNameWithExt = fileName;
      if (!fileName.contains('.')) {
        fileNameWithExt = '$fileName.dart';
      }

      // Create file
      final filePath = path.join(directoryPath, fileNameWithExt);
      final file = File(filePath);
      await file.create();

      // Refresh file list
      await _loadFilesFromDirectory(directoryPath);

      return file;
    } catch (e) {
      debugPrint('Error creating new file: $e');
      return null;
    }
  }

  /// Create a new folder in current directory
  Future<Directory?> createNewFolder(String folderName) async {
    final directoryPath = _ref.read(directoryPathProvider);
    if (directoryPath == null) return null;

    try {
      // Create folder
      final folderPath = path.join(directoryPath, folderName);
      final folder = Directory(folderPath);
      await folder.create();

      // Refresh file list
      await _loadFilesFromDirectory(directoryPath);

      return folder;
    } catch (e) {
      debugPrint('Error creating new folder: $e');
      return null;
    }
  }

  /// Read file contents
  Future<String> readFileContents(FileSystemEntity file) async {
    try {
      if (file is! File) return '';

      // Read file content
      return await file.readAsString();
    } catch (e) {
      debugPrint('Error reading file: $e');
      return '';
    }
  }

  /// Write to file
  Future<bool> writeToFile(FileSystemEntity file, String contents) async {
    try {
      if (file is! File) return false;

      // Write to file
      await file.writeAsString(contents);
      return true;
    } catch (e) {
      debugPrint('Error writing to file: $e');
      return false;
    }
  }

  /// Load files from directory
  Future<void> _loadFilesFromDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      final entities = await directory.list().toList();

      // Sort: directories first, then files, both alphabetically
      entities.sort((a, b) {
        // Directories first
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;

        // Then alphabetically by name
        return path.basename(a.path).compareTo(path.basename(b.path));
      });

      // Update provider
      _ref.read(filesListProvider.notifier).state = entities;
    } catch (e) {
      debugPrint('Error loading files: $e');
      _ref.read(filesListProvider.notifier).state = [];
    }
  }

  /// Add directory to recent list
  Future<void> _addToRecentDirectories(String directoryPath) async {
    final recentDirs = List<String>.from(_ref.read(recentDirectoriesProvider));

    // Add to start of list if not already there, otherwise move to start
    if (recentDirs.contains(directoryPath)) {
      recentDirs.remove(directoryPath);
    }

    recentDirs.insert(0, directoryPath);

    // Limit to 10 recent directories
    final limitedList = recentDirs.take(10).toList();

    // Update provider
    _ref.read(recentDirectoriesProvider.notifier).state = limitedList;

    // Persist recent directories
    await storage.write(
        key: 'recent_directories', value: limitedList.join('|'));
  }

  /// Load recent directories from storage
  Future<List<String>> loadRecentDirectories() async {
    try {
      final recentDirsString = await storage.read(key: 'recent_directories');
      if (recentDirsString == null) return [];

      final recentDirs = recentDirsString.split('|');

      // Update provider
      _ref.read(recentDirectoriesProvider.notifier).state = recentDirs;

      return recentDirs;
    } catch (e) {
      debugPrint('Error loading recent directories: $e');
      return [];
    }
  }

  /// Public method to refresh the file list in the current directory
  Future<void> refreshCurrentDirectory() async {
    final directoryPath = _ref.read(directoryPathProvider);
    if (directoryPath == null) return;

    _ref.read(explorerLoadingProvider.notifier).state = true;
    try {
      await _loadFilesFromDirectory(directoryPath);
    } finally {
      _ref.read(explorerLoadingProvider.notifier).state = false;
    }
  }
}

/// Provider for the explorer logic
final explorerLogicProvider = Provider<ExplorerLogic>((ref) {
  return ExplorerLogic(ref);
});
