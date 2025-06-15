import 'package:flutter/material.dart';
import 'repository_storage.dart';

/// Utility to check if a project is uploaded and get repo info, or show a dialog if not
class RunButtonHandler {
  /// Checks if the project is uploaded to GitHub
  ///
  /// Returns the RepositoryInfo if uploaded, otherwise shows a dialog and returns null
  static Future<RepositoryInfo?> checkProjectUploaded({
    required BuildContext context,
    required String projectPath,
  }) async {
    final repoInfo = await RepositoryStorage.getRepositoryInfo(projectPath);
    if (repoInfo == null) {
      // Show dialog prompting user to upload
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Project Not Uploaded'),
          content: const Text(
              'This project is not uploaded to GitHub. Please upload it first to enable running builds.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }
    return repoInfo;
  }
}
