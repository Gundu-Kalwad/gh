import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/ui/template/template_selection_screen.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';

/// Shows the template selection dialog
Future<void> showTemplateManager(BuildContext context, WidgetRef ref, String projectDirectory) async {
  // Print the provided project directory for debugging
  print('Original project directory provided: $projectDirectory');
  
  // Check if the project directory is a content URI
  final bool isContentUri = projectDirectory.startsWith('content:');
  String targetDirectory;
  
  if (isContentUri) {
    print('Content URI detected: $projectDirectory');
    // For content URIs, we'll use the original directory
    // Our native code can handle writing to content URIs directly
    targetDirectory = projectDirectory;
    print('Using original content URI for templates: $targetDirectory');
  } else {
    // For regular file paths, use the provided directory directly
    targetDirectory = projectDirectory;
    print('Using regular file path: $targetDirectory');
    
    try {
      // Make sure the directory exists
      final directory = Directory(targetDirectory);
      if (!await directory.exists()) {
        print('Creating directory: $targetDirectory');
        await directory.create(recursive: true);
      }
      
      // Test write access
      final testFile = File('$targetDirectory/test_write.txt');
      await testFile.writeAsString('Test write access');
      await testFile.delete();
      print('Successfully verified write access to directory');
    } catch (e) {
      print('Error accessing directory: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Directory Access Error'),
          content: Text('Cannot access the selected directory: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
  }
  
  // Navigate to the template selection screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TemplateSelectionScreen(
        projectDirectory: targetDirectory,
        originalDirectory: projectDirectory,
        isContentUri: isContentUri,
      ),
    ),
  );
}
