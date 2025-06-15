import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';
import 'run_button_handler.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:pro_coding_studio/logic/github_operations/github_repo_operations.dart';

enum RunButtonError {
  notUploaded,
  noGithubFolder,
}

class RunButtonLogic {
  /// Handles the Run button press:
  /// 1. Checks if project is uploaded (using RepositoryStorage)
  /// 2. Checks if .github folder exists in root
  /// 3. Shows dialog if either check fails
  static Future<void> handleRunButton(
      BuildContext context, WidgetRef ref) async {
    // Get the open folder/project URI from the explorer provider
    final String? projectPath = ref.read(directoryUriProvider);
    if (projectPath == null) {
      await _showErrorDialog(context, 'No project is open.');
      return;
    }

    // 1. Check if project is uploaded
    final repoInfo = await RunButtonHandler.checkProjectUploaded(
      context: context,
      projectPath: projectPath,
    );
    if (repoInfo == null) return;

    // 2. Check if .github folder exists in root
    final githubFolderUri = await _getGithubFolderUri(projectPath);
    if (githubFolderUri == null) {
      await _showErrorDialog(
        context,
        ".github folder not found in the root of this project. Please add a workflow before running.",
      );
      return;
    }

    // 3. Check if workflows folder exists inside .github
    final workflowsFolderUri = await _getWorkflowsFolderUri(githubFolderUri);
    if (workflowsFolderUri == null) {
      await _showErrorDialog(
        context,
        "'workflows' folder not found in .github. Please add a workflow before running.",
      );
      return;
    }

    // 4. Check for at least one .yaml or .yml file in workflows
    final hasYaml = await _checkYamlFileExists(workflowsFolderUri);
    if (!hasYaml) {
      await _showErrorDialog(
        context,
        "No workflow YAML file found in .github/workflows. Please add a workflow before running.",
      );
      return;
    }

    // If all checks pass, proceed with polling GitHub Actions and downloading artifact
    try {
      final owner = repoInfo.owner;
      final repo = repoInfo.repoName;
      final token = ref.read(githubTokenProvider);
      if (token == null || token.isEmpty) {
        await _showErrorDialog(
            context, 'GitHub token not found. Please login again.');
        return;
      }
      // Use the non-intrusive indicator: update repoOperationMessageProvider
      ref.read(uploadProgressProvider.notifier).state = 0.0; // Show indicator
      ref.read(repoOperationMessageProvider.notifier).state =
          'Polling workflow status...';
      String? runId;
      int pollCount = 0;
      const maxPolls = 60; // ~5min if 5s interval
      const pollInterval = Duration(seconds: 5);
      // Poll for latest workflow run completion
      while (pollCount < maxPolls) {
        final runsResp = await http.get(
          Uri.parse(
              'https://api.github.com/repos/$owner/$repo/actions/runs?per_page=1'),
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );
        if (runsResp.statusCode == 200) {
          final runs = jsonDecode(runsResp.body);
          if (runs['workflow_runs'] != null &&
              runs['workflow_runs'].isNotEmpty) {
            final latestRun = runs['workflow_runs'][0];
            runId = latestRun['id'].toString();
            final status = latestRun['status'];
            final conclusion = latestRun['conclusion'];
            // --- Poll jobs API for current step ---
            final jobsResp = await http.get(
              Uri.parse(
                  'https://api.github.com/repos/$owner/$repo/actions/runs/$runId/jobs'),
              headers: {
                'Authorization': 'token $token',
                'Accept': 'application/vnd.github.v3+json',
              },
            );
            if (jobsResp.statusCode == 200) {
              final jobs = jsonDecode(jobsResp.body);
              if (jobs['jobs'] != null && jobs['jobs'].isNotEmpty) {
                final job = jobs['jobs'][0];
                final steps = job['steps'] as List<dynamic>?;
                if (steps != null) {
                  final runningStep = steps.firstWhere(
                    (step) => step['status'] == 'in_progress',
                    orElse: () => null,
                  );
                  if (runningStep != null) {
                    ref.read(repoOperationMessageProvider.notifier).state =
                        'Running: ' + (runningStep['name'] ?? 'step');
                  } else {
                    // If no step in progress, show last completed step or job status
                    final lastStep = steps.lastWhere(
                      (step) => step['status'] == 'completed',
                      orElse: () => null,
                    );
                    if (lastStep != null) {
                      ref.read(repoOperationMessageProvider.notifier).state =
                          'Last completed: ${lastStep['name'] ?? 'step'}';
                    } else {
                      ref.read(repoOperationMessageProvider.notifier).state =
                          'Workflow status: $status';
                    }
                  }
                }
              }
            }
            // --- End jobs API polling ---
            if (status == 'completed') {
              ref.read(repoOperationMessageProvider.notifier).state =
                  (conclusion == 'success')
                      ? 'Workflow completed successfully.'
                      : 'Workflow failed.';
              if (conclusion == 'success') {
                break;
              } else {
                // Fetch and extract logs for failed run
                ref.read(repoOperationMessageProvider.notifier).state =
                    'Fetching logs for failed run...';
                try {
                  final logsResp = await http.get(
                    Uri.parse(
                        'https://api.github.com/repos/$owner/$repo/actions/runs/$runId/logs'),
                    headers: {
                      'Authorization': 'token $token',
                      'Accept': 'application/vnd.github.v3+json',
                    },
                  );
                  if (logsResp.statusCode == 200) {
                    // Save logs ZIP to temp, extract to Output directory
                    final tempDir =
                        await Directory.systemTemp.createTemp('run_logs');
                    final zipPath = '${tempDir.path}/logs.zip';
                    final zipFile = File(zipPath);
                    await zipFile.writeAsBytes(logsResp.bodyBytes);
                    // Ensure Output directory exists
                    final outputDirUri =
                        await _ensureOutputDirectory(projectPath);
                    if (outputDirUri == null) {
                      await _showErrorDialog(context,
                          'Failed to create/find Output directory for logs.');
                      return;
                    }
                    final result =
                        await DocumentFileHandler.extractZipToContentUri(
                            zipPath, outputDirUri);
                    await zipFile.delete();
                    await tempDir.delete(recursive: true);
                    if (result) {
                      await _showInfoDialog(context,
                          'Workflow run failed. Logs downloaded and extracted to Output directory.');
                    } else {
                      await _showErrorDialog(
                          context, 'Failed to extract workflow run logs ZIP.');
                    }
                  } else {
                    await _showErrorDialog(
                        context, 'Failed to fetch workflow run logs.');
                  }
                } catch (e) {
                  await _showErrorDialog(context,
                      'Error fetching workflow run logs: ' + e.toString());
                }
                return;
              }
            }
          }
        } else if (runsResp.statusCode == 401) {
          await _showErrorDialog(
              context, 'Unauthorized. Please re-login to GitHub.');
          return;
        }
        await Future.delayed(pollInterval);
        pollCount++;
      }
      // Step 2: Get artifacts for the run
      ref.read(repoOperationMessageProvider.notifier).state =
          'Fetching workflow artifacts...';
      final artifactsResp = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$owner/$repo/actions/runs/$runId/artifacts'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      if (artifactsResp.statusCode != 200) {
        await _showErrorDialog(
            context, 'Failed to fetch artifacts for workflow run.');
        return;
      }
      final artifactsData = jsonDecode(artifactsResp.body);
      if (artifactsData['artifacts'] == null ||
          artifactsData['artifacts'].isEmpty) {
        await _showErrorDialog(
            context, 'No artifacts found for latest workflow run.');
        return;
      }
      final artifact = artifactsData['artifacts'][0];
      final downloadUrl = artifact['archive_download_url'];
      // Step 3: Download artifact zip
      ref.read(repoOperationMessageProvider.notifier).state =
          'Downloading workflow artifact...';
      final artifactResp = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );
      if (artifactResp.statusCode != 200) {
        await _showErrorDialog(context, 'Failed to download artifact zip.');
        return;
      }
      // Step 4: Extract artifact zip to Output directory in project
      final outputDirUri = await _ensureOutputDirectory(projectPath);
      if (outputDirUri == null) {
        await _showErrorDialog(
            context, 'Failed to create/find Output directory.');
        return;
      }
      final bytes = artifactResp.bodyBytes;
      final success = await _writeAndExtractZip(outputDirUri, bytes);
      if (success) {
        ref.read(repoOperationMessageProvider.notifier).state =
            'Artifact downloaded and extracted to Output directory.';
        await _showInfoDialog(
            context, 'Artifact downloaded and extracted to Output directory.');
      } else {
        await _showErrorDialog(context, 'Failed to extract artifact ZIP.');
      }
    } catch (e) {
      await _showErrorDialog(
          context,
          'Error during workflow polling or artifact download: ' +
              e.toString());
    } finally {
      // Clear the indicator message and hide indicator
      ref.read(repoOperationMessageProvider.notifier).state = null;
      ref.read(uploadProgressProvider.notifier).state = null;
      // Refresh file explorer if Output directory was created or updated
      try {
        final docFileHandler = ref.read(documentFileHandlerProvider);
        await docFileHandler.refreshCurrentDirectory();
      } catch (e) {
        // Ignore errors, just best effort
      }
    }
  }

  /// Returns the URI of the .github folder if it exists, else null
  static Future<String?> _getGithubFolderUri(String projectPath) async {
    final files = await DocumentFileHandler.listFiles(projectPath);
    for (final file in files) {
      if (file.isDirectory && file.name == '.github') {
        return file.uri;
      }
    }
    return null;
  }

  /// Returns the URI of the workflows folder inside .github, else null
  static Future<String?> _getWorkflowsFolderUri(String githubFolderUri) async {
    final files = await DocumentFileHandler.listFiles(githubFolderUri);
    for (final file in files) {
      if (file.isDirectory && file.name == 'workflows') {
        return file.uri;
      }
    }
    return null;
  }

  /// Checks if at least one .yaml or .yml file exists in the workflows folder
  static Future<bool> _checkYamlFileExists(String workflowsFolderUri) async {
    final files = await DocumentFileHandler.listFiles(workflowsFolderUri);
    for (final file in files) {
      if (!file.isDirectory &&
          (file.name.endsWith('.yaml') || file.name.endsWith('.yml'))) {
        return true;
      }
    }
    return false;
  }

  /// Ensures an 'Output' directory exists in the project root and returns its URI
  static Future<String?> _ensureOutputDirectory(String projectPath) async {
    final files = await DocumentFileHandler.listFiles(projectPath);
    for (final file in files) {
      if (file.isDirectory && file.name == 'Output') {
        return file.uri;
      }
    }
    // Create Output directory if not found
    final created =
        await DocumentFileHandler.createDirectory(projectPath, 'Output');
    return created?.uri;
  }

  /// Writes the ZIP bytes to a temp file and extracts to the output directory using DocumentFileHandler
  static Future<bool> _writeAndExtractZip(
      String outputDirUri, List<int> bytes) async {
    try {
      final tempDir = await Directory.systemTemp.createTemp('artifact_zip');
      final zipPath = '${tempDir.path}/artifact.zip';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(bytes);
      // Use DocumentFileHandler to extract
      final result = await DocumentFileHandler.extractZipToContentUri(
          zipPath, outputDirUri);
      await zipFile.delete();
      await tempDir.delete(recursive: true);
      return result;
    } catch (e) {
      print('Error extracting ZIP to Output directory: $e');
      return false;
    }
  }

  static Future<void> _showErrorDialog(
      BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showInfoDialog(
      BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
