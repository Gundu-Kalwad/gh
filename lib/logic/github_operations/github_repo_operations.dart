import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';
import 'package:pro_coding_studio/logic/github_operations/artifact/repository_storage.dart';
import 'package:flutter/foundation.dart';

/// Providers for GitHub repository operations
final githubRepoOperationsProvider = Provider<GitHubRepoOperations>((ref) {
  return GitHubRepoOperations(ref);
});

/// Provider for upload progress
final uploadProgressProvider = StateProvider<double?>((ref) => null);

/// Provider for download progress
final downloadProgressProvider = StateProvider<double?>((ref) => null);

/// Provider for operation messages
final repoOperationMessageProvider = StateProvider<String?>((ref) => null);

/// Class for handling GitHub repository operations
class GitHubRepoOperations {
  final Ref _ref;

  GitHubRepoOperations(this._ref);

  // Helper method to check if a file is a GitHub workflow file
  bool _isGitHubWorkflowFile(String path) {
    return path.startsWith('.github/workflows/') &&
        (path.endsWith('.yml') || path.endsWith('.yaml'));
  }

  // Helper method to upload GitHub workflow files separately
  Future<bool> _uploadGitHubWorkflowFiles(Map<String, dynamic> repo,
      String repoName, String token, Map<String, String> pathMap) async {
    print('Uploading GitHub workflow files separately');
    bool success = false;

    // Find all workflow files
    List<String> workflowFiles = [];
    for (final uri in pathMap.keys) {
      final path = pathMap[uri]!;
      if (_isGitHubWorkflowFile(path)) {
        workflowFiles.add(uri);
      }
    }

    if (workflowFiles.isEmpty) {
      print('No GitHub workflow files found');
      return true; // No files to upload is still a success
    }

    print('Found ${workflowFiles.length} GitHub workflow files');

    try {
      // Create both directories and upload files using the Git Data API
      print(
          'Creating directory structure and uploading workflow files using Git Data API');

      // Step 1: Get the latest commit SHA
      final refResponse = await http.get(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (refResponse.statusCode != 200) {
        print(
            'Failed to get latest commit SHA: ${refResponse.statusCode}, ${refResponse.body}');
        return false;
      }

      final refData = jsonDecode(refResponse.body) as Map<String, dynamic>;
      final latestCommitSha = refData['object']['sha'];

      // Step 2: Get the commit to retrieve the tree SHA
      final commitResponse = await http.get(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/commits/$latestCommitSha'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (commitResponse.statusCode != 200) {
        print(
            'Failed to get commit: ${commitResponse.statusCode}, ${commitResponse.body}');
        return false;
      }

      final commitData =
          jsonDecode(commitResponse.body) as Map<String, dynamic>;
      final baseTreeSha = commitData['tree']['sha'];

      // Step 3: Create blobs for each workflow file
      List<Map<String, dynamic>> treeItems = [];

      // Add .github directory README
      final githubReadmeContent =
          '# GitHub Configuration\nThis directory contains GitHub-specific configuration files.';
      final githubReadmeBlobResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/blobs'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': githubReadmeContent,
          'encoding': 'utf-8',
        }),
      );

      if (githubReadmeBlobResponse.statusCode != 201) {
        print(
            'Failed to create .github README blob: ${githubReadmeBlobResponse.statusCode}, ${githubReadmeBlobResponse.body}');
        return false;
      }

      final githubReadmeBlobData =
          jsonDecode(githubReadmeBlobResponse.body) as Map<String, dynamic>;
      treeItems.add({
        'path': '.github/README.md',
        'mode': '100644',
        'type': 'blob',
        'sha': githubReadmeBlobData['sha'],
      });

      // Add .github/workflows directory README
      final workflowsReadmeContent =
          '# GitHub Workflows\nThis directory contains GitHub Actions workflow files.';
      final workflowsReadmeBlobResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/blobs'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': workflowsReadmeContent,
          'encoding': 'utf-8',
        }),
      );

      if (workflowsReadmeBlobResponse.statusCode != 201) {
        print(
            'Failed to create workflows README blob: ${workflowsReadmeBlobResponse.statusCode}, ${workflowsReadmeBlobResponse.body}');
        return false;
      }

      final workflowsReadmeBlobData =
          jsonDecode(workflowsReadmeBlobResponse.body) as Map<String, dynamic>;
      treeItems.add({
        'path': '.github/workflows/README.md',
        'mode': '100644',
        'type': 'blob',
        'sha': workflowsReadmeBlobData['sha'],
      });

      // Add each workflow file
      for (final fileUri in workflowFiles) {
        final filePath = pathMap[fileUri]!;
        print('Creating blob for workflow file: $filePath');

        String fileContent;
        if (_isBinaryFile(filePath)) {
          final bytes = await DocumentFileHandler.readFileBytes(fileUri);
          if (bytes == null || bytes.isEmpty) {
            print('Failed to read binary file: $filePath');
            continue;
          }
          fileContent = utf8.decode(bytes); // GitHub API expects UTF-8 content
        } else {
          fileContent = await DocumentFileHandler.readFileContent(fileUri);
        }

        final blobResponse = await http.post(
          Uri.parse(
              'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/blobs'),
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'content': fileContent,
            'encoding': 'utf-8',
          }),
        );

        if (blobResponse.statusCode != 201) {
          print(
              'Failed to create blob for $filePath: ${blobResponse.statusCode}, ${blobResponse.body}');
          continue;
        }

        final blobData = jsonDecode(blobResponse.body) as Map<String, dynamic>;
        treeItems.add({
          'path': filePath,
          'mode': '100644',
          'type': 'blob',
          'sha': blobData['sha'],
        });
      }

      // Step 4: Create a tree with all files
      print('Creating tree with ${treeItems.length} items');
      final createTreeResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/trees'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base_tree': baseTreeSha,
          'tree': treeItems,
        }),
      );

      if (createTreeResponse.statusCode != 201) {
        print(
            'Failed to create tree: ${createTreeResponse.statusCode}, ${createTreeResponse.body}');
        return false;
      }

      final treeData =
          jsonDecode(createTreeResponse.body) as Map<String, dynamic>;
      final newTreeSha = treeData['sha'];

      // Step 5: Create a commit
      print('Creating commit with the new tree');
      final createCommitResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/commits'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'Add GitHub workflow files',
          'tree': newTreeSha,
          'parents': [latestCommitSha],
        }),
      );

      if (createCommitResponse.statusCode != 201) {
        print(
            'Failed to create commit: ${createCommitResponse.statusCode}, ${createCommitResponse.body}');
        return false;
      }

      final newCommitData =
          jsonDecode(createCommitResponse.body) as Map<String, dynamic>;
      final newCommitSha = newCommitData['sha'];

      // Step 6: Update the reference
      print('Updating reference to point to the new commit');
      final updateRefResponse = await http.patch(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sha': newCommitSha,
          'force': false,
        }),
      );

      if (updateRefResponse.statusCode != 200) {
        print(
            'Failed to update reference: ${updateRefResponse.statusCode}, ${updateRefResponse.body}');
        return false;
      }

      print(
          'Successfully created directory structure and uploaded workflow files');
      success = true;
    } catch (e) {
      print(
          'Error creating directory structure and uploading workflow files: $e');
      return false;
    }

    // All workflow files have been uploaded in a single commit

    return success;
  }

  /// Upload the current project to GitHub
  ///
  /// Parameters:
  /// - repoName: Name for the GitHub repository
  /// - description: Description for the GitHub repository
  /// - isPrivate: Whether the repository should be private
  /// - directoryUri: URI of the directory to upload
  ///
  /// Returns true if successful, false otherwise
  Future<bool> uploadProjectToGitHub({
    required String repoName,
    required String directoryUri,
    String description = '',
    bool isPrivate = false,
  }) async {
    try {
      final token = _ref.read(githubTokenProvider);
      final username = _ref.read(githubUsernameProvider);

      if (token == null) {
        _ref.read(repoOperationMessageProvider.notifier).state =
            'GitHub token not found. Please sign in.';
        return false;
      }

      if (username == null) {
        _ref.read(repoOperationMessageProvider.notifier).state =
            'GitHub username not found. Please sign in.';
        return false;
      }

      // Reset progress
      _ref.read(uploadProgressProvider.notifier).state = 0.0;
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Checking repository...';

      // First check if the repository already exists
      Map<String, dynamic>? repo =
          await _checkRepositoryExists(token, username, repoName);

      if (repo == null) {
        // Repository doesn't exist, create it
        _ref.read(repoOperationMessageProvider.notifier).state =
            'Creating repository...';

        repo = await _createRepository(
          token: token,
          name: repoName,
          description: description,
          isPrivate: isPrivate,
        );

        if (repo == null) {
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Failed to create repository.';
          return false;
        }
      } else {
        // Repository already exists
        _ref.read(repoOperationMessageProvider.notifier).state =
            'Using existing repository...';
      }

      _ref.read(uploadProgressProvider.notifier).state = 0.2;
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Building file path map...';

      // Build a clean path map for all files in the directory
      final pathMap = await _buildFilePathMap(directoryUri);
      if (pathMap.isEmpty) {
        _ref.read(repoOperationMessageProvider.notifier).state =
            'No files found in the directory.';
        return false;
      }

      print('Built path map with ${pathMap.length} files');

      // Check for .gitignore file and load patterns
      List<String> gitignorePatterns = [];
      for (final fileUri in pathMap.keys) {
        final fileName = fileUri.split('/').last;
        if (fileName == '.gitignore') {
          print('Found .gitignore file, loading patterns...');
          final content = await DocumentFileHandler.readFileContent(fileUri);
          gitignorePatterns = _parseGitignoreContent(content);
          print('Loaded ${gitignorePatterns.length} patterns from .gitignore');
          break;
        }
      }

      // Use a more efficient approach - upload all files in a batch
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Preparing files for upload...';

      // First, get the latest commit SHA for the repository
      print('Getting latest commit SHA for repository');
      final refResponse = await http.get(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      String latestCommitSha = '';
      String? baseTreeSha;

      if (refResponse.statusCode == 200) {
        // Main branch exists
        final refData = jsonDecode(refResponse.body) as Map<String, dynamic>;
        latestCommitSha = refData['object']['sha'];
        print('Found main branch with commit SHA: $latestCommitSha');
      } else {
        // Try master branch if main doesn't exist
        final masterRefResponse = await http.get(
          Uri.parse(
              'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/master'),
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

        if (masterRefResponse.statusCode == 200) {
          // Master branch exists
          final refData =
              jsonDecode(masterRefResponse.body) as Map<String, dynamic>;
          latestCommitSha = refData['object']['sha'];
          print('Found master branch with commit SHA: $latestCommitSha');
        } else if (refResponse.statusCode == 409 &&
            refResponse.body.contains("Git Repository is empty")) {
          // Repository is empty, create initial commit with README using the Contents API
          print(
              'Repository is empty. Creating initial commit with README.md using Contents API');
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Initializing empty repository...';

          // Create README.md file using the Contents API (works with empty repos)
          final readmeContent = '# $repoName\n\nCreated with Pro Coding Studio';
          final createFileResponse = await http.put(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/README.md'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': 'Initial commit with README',
              'content': base64Encode(utf8.encode(readmeContent)),
              'branch': 'main',
            }),
          );

          if (createFileResponse.statusCode != 201) {
            // Try with master branch if main fails
            final createFileMasterResponse = await http.put(
              Uri.parse(
                  'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/README.md'),
              headers: {
                'Authorization': 'token $token',
                'Accept': 'application/vnd.github.v3+json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'message': 'Initial commit with README',
                'content': base64Encode(utf8.encode(readmeContent)),
                'branch': 'master',
              }),
            );

            if (createFileMasterResponse.statusCode != 201) {
              print('Failed to create README file: ${createFileResponse.body}');
              print(
                  'Also failed with master branch: ${createFileMasterResponse.body}');
              _ref.read(repoOperationMessageProvider.notifier).state =
                  'Failed to initialize repository.';
              return false;
            }
          }

          print('Successfully created README.md file');

          // Now get the reference to the newly created branch
          final newRefResponse = await http.get(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          );

          if (newRefResponse.statusCode == 200) {
            final refData =
                jsonDecode(newRefResponse.body) as Map<String, dynamic>;
            latestCommitSha = refData['object']['sha'];
            print('Found main branch with commit SHA: $latestCommitSha');
          } else {
            // Try master branch as fallback
            print('Main branch not found, trying master branch...');
            final masterRefResponse = await http.get(
              Uri.parse(
                  'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/master'),
              headers: {
                'Authorization': 'token $token',
                'Accept': 'application/vnd.github.v3+json',
              },
            );

            if (masterRefResponse.statusCode == 200) {
              final refData =
                  jsonDecode(masterRefResponse.body) as Map<String, dynamic>;
              latestCommitSha = refData['object']['sha'];
              print('Found master branch with commit SHA: $latestCommitSha');

              // Update message to indicate we're using master branch
              _ref.read(repoOperationMessageProvider.notifier).state =
                  'Using master branch for upload...';
            } else {
              // Neither main nor master branch found
              print(
                  'Neither main nor master branch found. Repository may be empty or inaccessible.');
              print(
                  'Main branch response: ${newRefResponse.statusCode}, ${newRefResponse.body}');
              print(
                  'Master branch response: ${masterRefResponse.statusCode}, ${masterRefResponse.body}');

              _ref.read(repoOperationMessageProvider.notifier).state =
                  'Failed to initialize repository. No valid branch found.';
              return false;
            }
          }

          // Now get the tree SHA
          final commitResponse = await http.get(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/commits/$latestCommitSha'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          );

          if (commitResponse.statusCode == 200) {
            final commitData =
                jsonDecode(commitResponse.body) as Map<String, dynamic>;
            baseTreeSha = commitData['tree']['sha'];
            print('Got base tree SHA: $baseTreeSha');
          } else {
            print(
                'Failed to get commit data: ${commitResponse.statusCode}, Response: ${commitResponse.body}');
            _ref.read(repoOperationMessageProvider.notifier).state =
                'Failed to initialize repository.';
            return false;
          }

          print('Successfully initialized repository with README.md');
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Repository initialized. Uploading files...';
        } else {
          print(
              'Failed to get repository reference. Status: ${refResponse.statusCode}, Response: ${refResponse.body}');
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Failed to upload files.';
          return false;
        }
      }

      // Get the latest commit tree if we don't already have it from the empty repo initialization
      if (baseTreeSha == null) {
        print('Getting latest commit tree');
        final commitResponse = await http.get(
          Uri.parse(
              'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/commits/$latestCommitSha'),
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

        if (commitResponse.statusCode != 200) {
          print(
              'Failed to get commit. Status: ${commitResponse.statusCode}, Response: ${commitResponse.body}');
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Failed to upload files.';
          return false;
        }

        final commitData =
            jsonDecode(commitResponse.body) as Map<String, dynamic>;
        baseTreeSha = commitData['tree']['sha'];
        print('Base tree SHA: $baseTreeSha');
      } else {
        print('Using base tree SHA from initial commit: $baseTreeSha');
      }

      // Prepare tree entries for all files
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Preparing files...';
      _ref.read(uploadProgressProvider.notifier).state = 0.3;

      List<Map<String, dynamic>> treeEntries = [];
      final fileUris = pathMap.keys.toList();
      int processedFiles = 0;

      for (final fileUri in fileUris) {
        try {
          final relativePath = pathMap[fileUri]!;

          // Check if file matches any gitignore patterns
          if (_isIgnoredByGitignore(relativePath, gitignorePatterns)) {
            print('Skipping file ignored by .gitignore: $relativePath');
            continue;
          }

          // Get the file content
          final content = await DocumentFileHandler.readFileContent(fileUri);

          // Create a blob for the file content
          final blobResponse;

          // Check if this is a binary file
          if (_isBinaryFile(relativePath)) {
            // For binary files, we need to use base64 encoding
            final bytes = await DocumentFileHandler.readFileBytes(fileUri);
            if (bytes == null || bytes.isEmpty) {
              print('Failed to read binary file: $relativePath');
              continue;
            }

            blobResponse = await http.post(
              Uri.parse(
                  'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/blobs'),
              headers: {
                'Authorization': 'token $token',
                'Accept': 'application/vnd.github.v3+json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'content': base64Encode(bytes),
                'encoding': 'base64',
              }),
            );
          } else {
            // For text files, use UTF-8 encoding
            blobResponse = await http.post(
              Uri.parse(
                  'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/blobs'),
              headers: {
                'Authorization': 'token $token',
                'Accept': 'application/vnd.github.v3+json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'content': content,
                'encoding': 'utf-8',
              }),
            );
          }

          if (blobResponse.statusCode != 201) {
            print(
                'Failed to create blob for $relativePath. Status: ${blobResponse.statusCode}, Response: ${blobResponse.body}');
            continue;
          }

          final blobData =
              jsonDecode(blobResponse.body) as Map<String, dynamic>;
          final blobSha = blobData['sha'];

          // Add entry to tree
          treeEntries.add({
            'path': relativePath,
            'mode': '100644', // Regular file
            'type': 'blob',
            'sha': blobSha,
          });

          processedFiles++;
          final progress = 0.3 + (0.4 * processedFiles / fileUris.length);
          _ref.read(uploadProgressProvider.notifier).state = progress;
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Preparing files... ($processedFiles/${fileUris.length})';

          print('Prepared file: $relativePath');
        } catch (e) {
          print('Error preparing file: $e');
        }
      }

      if (treeEntries.isEmpty) {
        print('No files to upload');
        _ref.read(repoOperationMessageProvider.notifier).state =
            'No files to upload.';
        return false;
      }

      // Try using the complete Git Data API workflow first (more efficient)
      try {
        final success = await _uploadUsingGitDataApi(
          repo: repo,
          repoName: repoName,
          token: token,
          treeEntries: treeEntries,
          totalFiles: treeEntries.length,
          directoryUri: directoryUri,
        );

        if (success) {
          print('Successfully uploaded project using Git Data API');
          _ref.read(uploadProgressProvider.notifier).state = 1.0;
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Upload complete!';

          // Reset progress after a short delay
          await Future.delayed(const Duration(seconds: 2));
          _ref.read(uploadProgressProvider.notifier).state = null;
          _ref.read(repoOperationMessageProvider.notifier).state = null;
          return true;
        } else {
          print('Git Data API upload failed, falling back to Contents API');
          // If Git Data API fails, we'll fall back to the Contents API below
        }
      } catch (e) {
        print('Error using Git Data API: $e');
        print('Falling back to Contents API');
        // If there's an error, we'll fall back to the Contents API below
      }

      // Switch to a more reliable approach - upload files individually using the Contents API
      // This is especially important for .github workflow files
      print('Uploading files individually using Contents API');
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Uploading files...';
      _ref.read(uploadProgressProvider.notifier).state = 0.7;

      // Group files by directory to create directories first
      Map<String, List<Map<String, dynamic>>> filesByDirectory = {};

      // First, organize files by directory
      for (var entry in treeEntries) {
        final path = entry['path'] as String;
        final lastSlashIndex = path.lastIndexOf('/');

        if (lastSlashIndex > 0) {
          // This file is in a subdirectory
          final directory = path.substring(0, lastSlashIndex);
          if (!filesByDirectory.containsKey(directory)) {
            filesByDirectory[directory] = [];
          }
          filesByDirectory[directory]!.add(entry);
        } else {
          // This file is in the root directory
          if (!filesByDirectory.containsKey('root')) {
            filesByDirectory['root'] = [];
          }
          filesByDirectory['root']!.add(entry);
        }
      }

      // Now upload files, starting with root directory
      int uploadedFiles = 0;
      int totalFiles = treeEntries.length;

      // First upload root files
      if (filesByDirectory.containsKey('root')) {
        for (var entry in filesByDirectory['root']!) {
          final path = entry['path'] as String;

          // Find the original file URI to get the content
          String? fileUri;
          for (final uri in pathMap.keys) {
            if (pathMap[uri] == path) {
              fileUri = uri;
              break;
            }
          }

          if (fileUri == null) {
            print('Could not find original file URI for $path');
            continue;
          }

          String content;
          if (_isBinaryFile(path)) {
            final bytes = await DocumentFileHandler.readFileBytes(fileUri);
            if (bytes == null || bytes.isEmpty) {
              print('Failed to read binary file: $path');
              continue;
            }
            content = base64Encode(bytes);
          } else {
            content = await DocumentFileHandler.readFileContent(fileUri);
            content = base64Encode(utf8.encode(content));
          }

          // Properly encode the path for the URL, especially important for paths with dots
          final encodedPath = Uri.encodeFull(path);
          print('Uploading file with encoded path: $encodedPath');

          // First check if the file already exists
          print('Checking if file already exists: $encodedPath');
          final checkFileResponse = await http.get(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$encodedPath'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          );

          // Prepare the request body
          Map<String, dynamic> requestBody = {
            'message': 'Update $path',
            'content': content,
            'branch': 'main',
          };

          // If file exists, include its SHA to update it
          if (checkFileResponse.statusCode == 200) {
            final fileData = jsonDecode(checkFileResponse.body);
            final fileSha = fileData['sha'];
            print('File exists, updating with SHA: $fileSha');
            requestBody['sha'] = fileSha;
          } else {
            print('File does not exist, creating new file');
            requestBody['message'] = 'Add $path';
          }

          final createFileResponse = await http.put(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$encodedPath'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          if (createFileResponse.statusCode != 201) {
            print(
                'Failed to upload file $path: ${createFileResponse.statusCode}, ${createFileResponse.body}');
          } else {
            print('Successfully uploaded file: $path');
          }

          uploadedFiles++;
          final progress = 0.7 + (0.3 * uploadedFiles / totalFiles);
          _ref.read(uploadProgressProvider.notifier).state = progress;
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Uploading files... ($uploadedFiles/$totalFiles)';
        }
      }

      // Then process directories in order of depth (shallowest first)
      List<String> directories =
          filesByDirectory.keys.where((dir) => dir != 'root').toList();

      // Sort directories by depth (shallowest first) to ensure parent directories are created before children
      directories
          .sort((a, b) => a.split('/').length.compareTo(b.split('/').length));

      // Process .github directories first if they exist
      bool hasGithubDir = directories.any((dir) => dir.startsWith('.github'));

      if (hasGithubDir) {
        print(
            'Found .github directories - using a different approach for these special directories');

        // Extract .github files from the list for special handling
        List<String> githubDirs =
            directories.where((dir) => dir.startsWith('.github')).toList();
        directories.removeWhere((dir) => dir.startsWith('.github'));

        // Process .github files separately
        for (var githubDir in githubDirs) {
          print('Processing .github directory: $githubDir');

          // Get all files in this .github directory
          List<Map<String, dynamic>> githubFiles =
              filesByDirectory[githubDir] ?? [];

          // Upload each .github file directly to the main branch
          for (var entry in githubFiles) {
            final path = entry['path'] as String;

            // Find the original file URI to get the content
            String? fileUri;
            for (final uri in pathMap.keys) {
              if (pathMap[uri] == path) {
                fileUri = uri;
                break;
              }
            }

            if (fileUri == null) {
              print('Could not find original file URI for $path');
              continue;
            }

            String content;
            if (_isBinaryFile(path)) {
              final bytes = await DocumentFileHandler.readFileBytes(fileUri);
              if (bytes == null || bytes.isEmpty) {
                print('Failed to read binary file: $path');
                continue;
              }
              content = base64Encode(bytes);
            } else {
              content = await DocumentFileHandler.readFileContent(fileUri);
              content = base64Encode(utf8.encode(content));
            }

            // Use a simpler approach for .github files - create directories step by step
            print('Uploading GitHub workflow file: $path');

            try {
              // Step 1: Check if .github directory exists
              final checkDotGithubResponse = await http.get(
                Uri.parse(
                    'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/.github'),
                headers: {
                  'Authorization': 'token $token',
                  'Accept': 'application/vnd.github.v3+json',
                },
              );

              bool dotGithubExists = checkDotGithubResponse.statusCode == 200;
              print('.github directory exists: $dotGithubExists');

              // If .github doesn't exist, create it with README
              if (!dotGithubExists) {
                print('Creating .github directory with README');
                final createDotGithubResponse = await http.put(
                  Uri.parse(
                      'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/.github/README.md'),
                  headers: {
                    'Authorization': 'token $token',
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'message': 'Create .github directory',
                    'content': base64Encode(utf8.encode(
                        '# GitHub Configuration\nThis directory contains GitHub-specific configuration files.')),
                    'branch': 'main',
                  }),
                );

                if (createDotGithubResponse.statusCode != 201) {
                  print(
                      'Failed to create .github directory: ${createDotGithubResponse.statusCode}, ${createDotGithubResponse.body}');
                  continue;
                }

                print('Successfully created .github directory');
                // Wait for GitHub to process the directory creation
                await Future.delayed(const Duration(seconds: 3));
              }

              // Step 2: Check if .github/workflows directory exists
              final checkWorkflowsDirResponse = await http.get(
                Uri.parse(
                    'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/.github/workflows'),
                headers: {
                  'Authorization': 'token $token',
                  'Accept': 'application/vnd.github.v3+json',
                },
              );

              bool workflowsDirExists =
                  checkWorkflowsDirResponse.statusCode == 200;
              print('.github/workflows directory exists: $workflowsDirExists');

              // If .github/workflows doesn't exist, create it with README
              if (!workflowsDirExists) {
                print('Creating .github/workflows directory with README');
                final createWorkflowsDirResponse = await http.put(
                  Uri.parse(
                      'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/.github/workflows/README.md'),
                  headers: {
                    'Authorization': 'token $token',
                    'Accept': 'application/vnd.github.v3+json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'message': 'Create .github/workflows directory',
                    'content': base64Encode(utf8.encode(
                        '# GitHub Workflows\nThis directory contains GitHub Actions workflow files.')),
                    'branch': 'main',
                  }),
                );

                if (createWorkflowsDirResponse.statusCode != 201) {
                  print(
                      'Failed to create .github/workflows directory: ${createWorkflowsDirResponse.statusCode}, ${createWorkflowsDirResponse.body}');
                  continue;
                }

                print('Successfully created .github/workflows directory');
                // Wait for GitHub to process the directory creation
                await Future.delayed(const Duration(seconds: 3));
              }

              // Step 3: Check if the workflow file already exists
              print('Checking if workflow file already exists: $path');
              final checkFileResponse = await http.get(
                Uri.parse(
                    'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$path'),
                headers: {
                  'Authorization': 'token $token',
                  'Accept': 'application/vnd.github.v3+json',
                },
              );

              // Prepare the request body
              Map<String, dynamic> requestBody = {
                'message': 'Update $path',
                'content': content,
                'branch': 'main',
              };

              // If file exists, include its SHA to update it
              if (checkFileResponse.statusCode == 200) {
                final fileData = jsonDecode(checkFileResponse.body);
                final fileSha = fileData['sha'];
                print('Workflow file exists, updating with SHA: $fileSha');
                requestBody['sha'] = fileSha;
              } else {
                print('Workflow file does not exist, creating new file');
                requestBody['message'] = 'Add $path';
              }

              // Now upload the workflow file using the Contents API
              final createFileResponse = await http.put(
                Uri.parse(
                    'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$path'),
                headers: {
                  'Authorization': 'token $token',
                  'Accept': 'application/vnd.github.v3+json',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(requestBody),
              );

              if (createFileResponse.statusCode != 201) {
                print(
                    'Failed to upload workflow file: ${createFileResponse.statusCode}, ${createFileResponse.body}');
                continue;
              }

              print('Successfully uploaded GitHub workflow file: $path');
              uploadedFiles++;
            } catch (e) {
              print('Error uploading GitHub workflow file: $e');
              continue;
            }
            final progress = 0.7 + (0.3 * uploadedFiles / totalFiles);
            _ref.read(uploadProgressProvider.notifier).state = progress;
            _ref.read(repoOperationMessageProvider.notifier).state =
                'Uploading files... ($uploadedFiles/$totalFiles)';
          }
        }

        // Move .github directories to the front of the list
        directories.sort((a, b) {
          if (a.startsWith('.github')) return -1;
          if (b.startsWith('.github')) return 1;
          return a.split('/').length.compareTo(b.split('/').length);
        });
      }

      for (var directory in directories) {
        print('Processing directory: $directory');

        // Upload files directly without creating placeholder files
        for (var entry in filesByDirectory[directory]!) {
          final path = entry['path'] as String;

          // Find the original file URI to get the content
          String? fileUri;
          for (final uri in pathMap.keys) {
            if (pathMap[uri] == path) {
              fileUri = uri;
              break;
            }
          }

          if (fileUri == null) {
            print('Could not find original file URI for $path');
            continue;
          }

          String content;
          if (_isBinaryFile(path)) {
            final bytes = await DocumentFileHandler.readFileBytes(fileUri);
            if (bytes == null || bytes.isEmpty) {
              print('Failed to read binary file: $path');
              continue;
            }
            content = base64Encode(bytes);
          } else {
            content = await DocumentFileHandler.readFileContent(fileUri);
            content = base64Encode(utf8.encode(content));
          }

          // Properly encode the path for the URL, especially important for paths with dots
          final encodedPath = Uri.encodeFull(path);
          print('Uploading file with encoded path: $encodedPath');

          // Special handling for .github files in logs
          if (path.startsWith('.github/')) {
            print('Uploading .github file: $path');
          }

          // First check if the file already exists
          print('Checking if file already exists: $encodedPath');
          final checkFileResponse = await http.get(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$encodedPath'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
            },
          );

          // Prepare the request body
          Map<String, dynamic> requestBody = {
            'message': 'Update $path',
            'content': content,
            'branch': 'main',
          };

          // If file exists, include its SHA to update it
          if (checkFileResponse.statusCode == 200) {
            final fileData = jsonDecode(checkFileResponse.body);
            final fileSha = fileData['sha'];
            print('File exists, updating with SHA: $fileSha');
            requestBody['sha'] = fileSha;
          } else {
            print('File does not exist, creating new file');
            requestBody['message'] = 'Add $path';
          }

          final createFileResponse = await http.put(
            Uri.parse(
                'https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$encodedPath'),
            headers: {
              'Authorization': 'token $token',
              'Accept': 'application/vnd.github.v3+json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          );

          if (createFileResponse.statusCode != 201) {
            print(
                'Failed to upload file $path: ${createFileResponse.statusCode}, ${createFileResponse.body}');
            // For .github files, print more detailed debug information
            if (path.startsWith('.github/')) {
              print('DEBUG - .github file upload failed:');
              print('  Path: $path');
              print('  Encoded path: $encodedPath');
              print(
                  '  URL: https://api.github.com/repos/${repo['owner']['login']}/$repoName/contents/$encodedPath');
              print('  Response code: ${createFileResponse.statusCode}');
              print('  Response body: ${createFileResponse.body}');
            }
          } else {
            print('Successfully uploaded file: $path');
          }

          uploadedFiles++;
          final progress = 0.7 + (0.3 * uploadedFiles / totalFiles);
          _ref.read(uploadProgressProvider.notifier).state = progress;
          _ref.read(repoOperationMessageProvider.notifier).state =
              'Uploading files... ($uploadedFiles/$totalFiles)';
        }
      }

      print('Successfully uploaded $uploadedFiles files to GitHub');

      // Check if there are any GitHub workflow files to upload separately
      bool hasWorkflowFiles = false;
      for (final uri in pathMap.keys) {
        final path = pathMap[uri]!;
        if (_isGitHubWorkflowFile(path)) {
          hasWorkflowFiles = true;
          break;
        }
      }

      if (hasWorkflowFiles) {
        print('Found GitHub workflow files, uploading them separately');
        // Remove workflow files from pathMap to avoid duplicate uploads
        Map<String, String> workflowPathMap = {};
        pathMap.forEach((uri, path) {
          if (_isGitHubWorkflowFile(path)) {
            workflowPathMap[uri] = path;
          }
        });

        // Upload workflow files separately
        final workflowUploadSuccess = await _uploadGitHubWorkflowFiles(
            repo, repoName, token, workflowPathMap);
        if (workflowUploadSuccess) {
          print('Successfully uploaded GitHub workflow files');
        } else {
          print('Failed to upload GitHub workflow files');
        }
      }

      // Check if we uploaded at least some files
      if (uploadedFiles == 0 && !hasWorkflowFiles) {
        print('Failed to upload any files');
        _ref.read(repoOperationMessageProvider.notifier).state =
            'Failed to upload files.';
        return false;
      }

      // Reset progress after a short delay
      await Future.delayed(const Duration(seconds: 1));
      _ref.read(uploadProgressProvider.notifier).state = null;
      _ref.read(repoOperationMessageProvider.notifier).state = null;

      // Return true to indicate success
      return true;
    } catch (e) {
      print('Error uploading project: $e');
      _ref.read(uploadProgressProvider.notifier).state = null;
      _ref.read(repoOperationMessageProvider.notifier).state = null;
      return false;
    }
  }

  /// Download a project from GitHub
  ///
  /// Parameters:
  /// - repoOwner: Owner of the repository
  /// - repoName: Name of the repository
  /// - branch: Branch to download (default: main)
  /// - targetDirectoryUri: URI of the directory to download to
  /// Download a project from GitHub and extract it to the target directory
  Future<bool> downloadProjectFromGitHub({
    required String repoOwner,
    required String repoName,
    required String branch,
    required String targetDirectoryUri,
  }) async {
    try {
      _ref.read(downloadProgressProvider.notifier).state = 0.1;
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Downloading project...';

      // Create the download URL for the branch archive
      final downloadUrl =
          'https://github.com/$repoOwner/$repoName/archive/refs/heads/$branch.zip';

      // Download the ZIP file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        _ref.read(downloadProgressProvider.notifier).state = null;
        _ref.read(repoOperationMessageProvider.notifier).state = null;
        return false;
      }

      _ref.read(downloadProgressProvider.notifier).state = 0.4;
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Extracting files...';

      // Extract the ZIP archive
      final bytes = response.bodyBytes;

      // Try to extract directly to the content URI if possible
      bool extractionSuccess = false;

      if (targetDirectoryUri.startsWith('content://')) {
        // Save the ZIP file to a temporary location
        final tempDirPath = await DocumentFileHandler.createTempDirectory();
        if (tempDirPath != null) {
          final zipFilePath = '$tempDirPath/repo.zip';
          await File(zipFilePath).writeAsBytes(bytes);

          // Try to extract directly to the content URI
          try {
            print(
                'Attempting direct extraction to content URI: $targetDirectoryUri');
            extractionSuccess =
                await DocumentFileHandler.extractZipToContentUri(
                    zipFilePath, targetDirectoryUri);
            print('Direct extraction result: $extractionSuccess');
          } catch (e) {
            print('Error during direct extraction: $e');
            extractionSuccess = false;
          }

          // Clean up the temporary ZIP file
          await File(zipFilePath).delete();
        }
      }

      // If direct extraction failed or wasn't applicable, use the fallback method
      if (!extractionSuccess) {
        print('Using fallback extraction method');

        // Create a temporary directory to extract the files
        final tempDirPath = await DocumentFileHandler.createTempDirectory();
        if (tempDirPath == null) {
          _ref.read(downloadProgressProvider.notifier).state = null;
          _ref.read(repoOperationMessageProvider.notifier).state = null;
          return false;
        }

        // Extract all files to the temp directory
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            File('$tempDirPath/$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            Directory('$tempDirPath/$filename').createSync(recursive: true);
          }
        }

        _ref.read(downloadProgressProvider.notifier).state = 0.7;
        _ref.read(repoOperationMessageProvider.notifier).state =
            'Copying files to project...';

        // Get the root folder of the extracted archive (usually repoName-branch)
        final rootDir = Directory(tempDirPath)
            .listSync()
            .firstWhere((entity) => entity is Directory) as Directory;

        // Copy files from the temp directory to the target directory
        await _copyFilesToDocumentTree(rootDir.path, targetDirectoryUri);

        // Clean up the temp directory
        await Directory(tempDirPath).delete(recursive: true);
      } else {
        _ref.read(downloadProgressProvider.notifier).state = 0.9;
        _ref.read(repoOperationMessageProvider.notifier).state =
            'Extraction complete!';
      }

      _ref.read(downloadProgressProvider.notifier).state = 1.0;
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Download complete!';

      // Note: Temp directory cleanup is handled in the fallback method

      // Reset progress after a short delay
      await Future.delayed(const Duration(seconds: 1));
      _ref.read(downloadProgressProvider.notifier).state = null;
      _ref.read(repoOperationMessageProvider.notifier).state = null;

      return true;
    } catch (e) {
      print('Error downloading project: $e');
      _ref.read(downloadProgressProvider.notifier).state = null;
      _ref.read(repoOperationMessageProvider.notifier).state = null;
      return false;
    }
  }

  /// Check if a repository already exists (not used, kept for reference)
  // This method is not used anymore, we use _checkRepositoryExists instead

  /// Uploads all files using the Git Data API in a single commit
  /// This is more efficient than uploading files individually
  Future<bool> _uploadUsingGitDataApi({
    required Map<String, dynamic> repo,
    required String repoName,
    required String token,
    required List<Map<String, dynamic>> treeEntries,
    required int totalFiles,
    required String directoryUri,
  }) async {
    try {
      _ref.read(repoOperationMessageProvider.notifier).state =
          'Creating Git tree...';
      _ref.read(uploadProgressProvider.notifier).state = 0.7;

      // Step 1: Get the latest commit SHA to use as the parent
      print('Getting latest commit SHA for main branch');
      final refResponse = await http.get(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      // If main branch doesn't exist, try master branch
      String baseCommitSha;
      if (refResponse.statusCode != 200) {
        print('Main branch not found, trying master branch');
        final masterRefResponse = await http.get(
          Uri.parse(
              'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/master'),
          headers: {
            'Authorization': 'token $token',
            'Accept': 'application/vnd.github.v3+json',
          },
        );

        if (masterRefResponse.statusCode != 200) {
          print('Neither main nor master branch found');
          return false;
        }

        final masterRefData = jsonDecode(masterRefResponse.body);
        baseCommitSha = masterRefData['object']['sha'];
      } else {
        final refData = jsonDecode(refResponse.body);
        baseCommitSha = refData['object']['sha'];
      }

      print('Base commit SHA: $baseCommitSha');

      // Step 2: Create a tree with all the blobs
      // Note: We're NOT specifying a base_tree, which means this will completely replace all files
      print(
          'Creating tree with ${treeEntries.length} entries (complete repository replacement)');
      final createTreeResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/trees'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Omitting base_tree to create a completely new tree without merging with existing files
          'tree': treeEntries,
        }),
      );

      if (createTreeResponse.statusCode != 201) {
        print(
            'Failed to create tree: ${createTreeResponse.statusCode}, ${createTreeResponse.body}');
        return false;
      }

      final treeData = jsonDecode(createTreeResponse.body);
      final treeSha = treeData['sha'];
      print('Created tree with SHA: $treeSha');

      _ref.read(repoOperationMessageProvider.notifier).state =
          'Creating commit...';
      _ref.read(uploadProgressProvider.notifier).state = 0.8;

      // Step 3: Create a commit with the tree
      print('Creating commit');
      final createCommitResponse = await http.post(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/commits'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': 'Upload project files',
          'tree': treeSha,
          'parents': [baseCommitSha],
        }),
      );

      if (createCommitResponse.statusCode != 201) {
        print(
            'Failed to create commit: ${createCommitResponse.statusCode}, ${createCommitResponse.body}');
        return false;
      }

      final commitData = jsonDecode(createCommitResponse.body);
      final commitSha = commitData['sha'];
      print('Created commit with SHA: $commitSha');

      _ref.read(repoOperationMessageProvider.notifier).state =
          'Updating branch reference...';
      _ref.read(uploadProgressProvider.notifier).state = 0.9;

      // Step 4: Update the branch reference to point to the new commit
      print('Updating branch reference');
      final updateRefResponse = await http.patch(
        Uri.parse(
            'https://api.github.com/repos/${repo['owner']['login']}/$repoName/git/refs/heads/main'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sha': commitSha,
          'force': false,
        }),
      );

      if (updateRefResponse.statusCode != 200) {
        print(
            'Failed to update reference: ${updateRefResponse.statusCode}, ${updateRefResponse.body}');
        return false;
      }
      debugPrint('Project uploaded to GitHub successfully');
      // Track repo info for this project
      try {
        final projectPath =
            directoryUri; // Use directoryUri as unique project key
        final repoOwner = repo['owner']['login'];
        final repoInfo = RepositoryInfo(
          owner: repoOwner,
          repoName: repoName,
          lastUploadTimestamp: DateTime.now(),
        );
        await RepositoryStorage.saveRepositoryInfo(projectPath, repoInfo);
        debugPrint('Saved repository info for project: '
            'owner=[32m$repoOwner[0m, repo=[32m$repoName[0m, path=[34m$projectPath[0m');
      } catch (e) {
        debugPrint('Failed to save repository info: $e');
      }
      return true;
    } catch (e) {
      print('Error in Git Data API upload: $e');
      return false;
    }
  }

  /// Check if a repository already exists
  Future<Map<String, dynamic>?> _checkRepositoryExists(
      String token, String owner, String repoName) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repoName'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        // Repository exists
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Repository doesn't exist or other error
        return null;
      }
    } catch (e) {
      print('Error checking repository: $e');
      return null;
    }
  }

  /// Create a new repository on GitHub
  Future<Map<String, dynamic>?> _createRepository({
    required String token,
    required String name,
    String description = '',
    bool isPrivate = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.github.com/user/repos'),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'private': isPrivate,
          'auto_init': false,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Error creating repository: ${response.body}');
        // Check if the error is because the repository already exists
        if (response.body.contains('name already exists')) {
          final username = _ref.read(githubUsernameProvider);
          if (username != null) {
            // Try to get the existing repository
            return await _checkRepositoryExists(token, username, name);
          }
        }
        return null;
      }
    } catch (e) {
      print('Error creating repository: $e');
      return null;
    }
  }

  /// Copy files from a local directory to a DocumentFile directory
  Future<bool> _copyFilesToDocumentTree(
      String sourceDirPath, String targetDirUri) async {
    try {
      print('Copying files from $sourceDirPath to $targetDirUri');
      final sourceDir = Directory(sourceDirPath);

      // Use non-recursive listing to avoid copying nested directories multiple times
      final entities = sourceDir.listSync(recursive: false);
      print('Found ${entities.length} items in source directory');

      // Track processed files to avoid duplicates
      int processedFiles = 0;

      for (final entity in entities) {
        try {
          if (entity is File) {
            // Process individual files
            final fileName = path.basename(entity.path);
            print('Processing file: $fileName');

            // Create the file in the target directory
            final fileContent = await entity.readAsString();
            final newFile =
                await DocumentFileHandler.createFile(targetDirUri, fileName);

            if (newFile != null) {
              await DocumentFileHandler.writeFileContent(
                  newFile.uri, fileContent);
              processedFiles++;
            }
          } else if (entity is Directory) {
            // For directories, create them in the target and process their contents separately
            final dirName = path.basename(entity.path);
            print('Processing directory: $dirName');

            // Skip certain directories that shouldn't be copied
            if (_shouldSkipDirectory(dirName)) {
              print('Skipping directory: $dirName');
              continue;
            }

            // Create the directory in the target
            final newDir = await DocumentFileHandler.createDirectory(
                targetDirUri, dirName);
            if (newDir != null) {
              // Recursively copy contents of this directory
              await _copyDirectoryContents(entity.path, newDir.uri);
            }
          }
        } catch (e) {
          print('Error processing entity ${entity.path}: $e');
          // Continue with next entity even if this one fails
        }
      }

      print('Successfully processed $processedFiles files');
      return true;
    } catch (e) {
      print('Error copying files to document tree: $e');
      return false;
    }
  }

  /// Helper method to copy contents of a directory without recursion issues
  Future<void> _copyDirectoryContents(
      String sourceDirPath, String targetDirUri) async {
    try {
      final sourceDir = Directory(sourceDirPath);
      final entities = sourceDir.listSync(recursive: false);

      for (final entity in entities) {
        try {
          if (entity is File) {
            // Process file
            final fileName = path.basename(entity.path);

            // Skip files that should be skipped, but not binary files
            if (_shouldSkipFile(fileName)) {
              print('Skipping file: $fileName');
              continue;
            }

            // Create the file in the target directory
            try {
              if (_isBinaryFile(fileName)) {
                // Handle binary files by reading as bytes
                final fileBytes = await entity.readAsBytes();
                final newFile = await DocumentFileHandler.createFile(
                    targetDirUri, fileName);

                if (newFile != null) {
                  await DocumentFileHandler.writeFileBytes(
                      newFile.uri, fileBytes);
                }
              } else {
                // Handle text files
                final fileContent = await entity.readAsString();
                final newFile = await DocumentFileHandler.createFile(
                    targetDirUri, fileName);

                if (newFile != null) {
                  await DocumentFileHandler.writeFileContent(
                      newFile.uri, fileContent);
                }
              }
            } catch (e) {
              print('Error reading or writing file $fileName: $e');
              // Continue with next file
            }
          } else if (entity is Directory) {
            // For directories, create them and process recursively
            final dirName = path.basename(entity.path);

            // Skip certain directories
            if (_shouldSkipDirectory(dirName)) {
              print('Skipping directory: $dirName');
              continue;
            }

            // Create the directory in the target
            final newDir = await DocumentFileHandler.createDirectory(
                targetDirUri, dirName);
            if (newDir != null) {
              // Recursively process this directory
              await _copyDirectoryContents(entity.path, newDir.uri);
            }
          }
        } catch (e) {
          print('Error processing entity in directory: $e');
          // Continue with next entity
        }
      }
    } catch (e) {
      print('Error copying directory contents: $e');
    }
  }

  /// Build a clean path map for uploading files to GitHub
  /// Returns a mapping of file URIs to their clean relative paths
  Future<Map<String, String>> _buildFilePathMap(String baseUri) async {
    Map<String, String> pathMap = {};

    // Helper function to process a directory
    Future<void> processDirectory(
        String dirUri, List<String> currentPath) async {
      print(
          'Processing directory: $dirUri with current path: ${currentPath.join('/')}');

      try {
        final items = await DocumentFileHandler.listFiles(dirUri);

        for (final item in items) {
          final name = item.name ?? 'unknown';

          // Special handling for .github folders - always include them
          if (name == '.github' || name.startsWith('.github/')) {
            print('Found GitHub folder/file: $name - including in upload');
          }
          // Skip files/directories that should be ignored
          else if (_shouldSkipFile(name) ||
              (item.isDirectory && _shouldSkipDirectory(name))) {
            print('Skipping ${item.isDirectory ? "directory" : "file"}: $name');
            continue;
          }

          if (item.isDirectory) {
            // Create a new path context for this subdirectory
            List<String> newPath = List.from(currentPath);
            newPath.add(name);

            print('Found directory: $name, new path: ${newPath.join('/')}');

            // Process the subdirectory recursively
            await processDirectory(item.uri, newPath);
          } else {
            // We now properly handle binary files, so don't skip them
            // Just log that we found a binary file
            if (_isBinaryFile(name)) {
              print(
                  'Found binary file: $name - will upload with base64 encoding');
            }

            // Build clean path for this file
            String relativePath;
            if (currentPath.isEmpty) {
              relativePath = name; // Just filename for root directory
            } else {
              relativePath =
                  '${currentPath.join('/')}/$name'; // dir/file.txt format
            }

            print('Mapping file: $name to path: $relativePath');

            // Store the mapping
            pathMap[item.uri] = relativePath;
          }
        }
      } catch (e) {
        print('Error processing directory $dirUri: $e');
      }
    }

    // Start processing from the base directory with empty path
    await processDirectory(baseUri, []);

    print('Built file path map with ${pathMap.length} entries');
    return pathMap;
  }

  // Note: _getRelativePath was removed as it's been replaced by _buildFilePathMap

  /// Check if a file is likely binary based on its extension
  bool _isBinaryFile(String fileName) {
    // Make sure we have a valid file name with an extension
    if (fileName.isEmpty || !fileName.contains('.')) {
      return false;
    }

    // List of common binary file extensions
    final binaryExtensions = [
      '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.ico',
      '.svg', // Images
      '.zip', '.rar', '.7z', '.tar', '.gz', '.jar', '.war', // Archives
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', // Documents
      '.mp3', '.mp4', '.avi', '.mov', '.flv', '.wmv', '.wav', '.ogg', // Media
      '.exe', '.dll', '.so', '.dylib', '.bin',
      '.dat', // Executables and binary data
      '.db', '.sqlite', '.mdb', // Databases
      '.ttf', '.otf', '.woff', '.woff2', // Fonts
      '.class', '.pyc', '.pyo', // Compiled code
      '.webp', '.tiff', '.psd' // More image formats
    ];

    try {
      final extension =
          fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
      return binaryExtensions.contains(extension);
    } catch (e) {
      print('Error checking if file is binary: $e');
      return false;
    }
  }

  /// Check if a file should be skipped based on its name or path
  bool _shouldSkipFile(String fileName) {
    // Make sure we don't skip .github workflow files
    if (fileName.contains('.github/workflows')) {
      return false;
    }

    // Modify this if want persnal gitignore files
    final skipPatterns = [
      /*
      '.git/', '.gitattributes', // Git files
      '.DS_Store', 'Thumbs.db', // System files
      '.lock', '.log', // Lock and log files
    */
    ];

    return skipPatterns.any((pattern) => fileName.contains(pattern));
  }

  /// Check if a directory should be skipped during copy
  bool _shouldSkipDirectory(String dirName) {
    // Make sure we don't skip .github directories
    if (dirName == '.github' || dirName.startsWith('.github/')) {
      return false;
    }

    // Modify this if want persnal gitignore directories
    final skipDirs = [
      /*
      '.git', // Git directories
      '.dart_tool', '.pub', 'build', '.gradle', // Build directories
      'node_modules', 'vendor', // Dependency directories
      '.idea', '.vscode', // IDE directories
    */
    ];

    return skipDirs.contains(dirName);
  }

  /// Parse the content of a .gitignore file into a list of patterns
  List<String> _parseGitignoreContent(String content) {
    final List<String> patterns = [];

    // Split the content into lines and process each line
    for (String line in content.split('\n')) {
      // Remove comments and trim whitespace
      final commentIndex = line.indexOf('#');
      if (commentIndex >= 0) {
        line = line.substring(0, commentIndex);
      }
      line = line.trim();

      // Skip empty lines
      if (line.isEmpty) continue;

      // Add valid patterns
      patterns.add(line);
    }

    return patterns;
  }

  /// Check if a file path matches any gitignore patterns
  bool _isIgnoredByGitignore(String filePath, List<String> gitignorePatterns) {
    if (gitignorePatterns.isEmpty) return false;

    // Normalize the file path
    final normalizedPath = filePath.replaceAll('\\', '/');

    for (final pattern in gitignorePatterns) {
      // Handle negation patterns (patterns starting with !)
      if (pattern.startsWith('!')) {
        final negatedPattern = pattern.substring(1);
        if (_matchesGitignorePattern(normalizedPath, negatedPattern)) {
          return false; // Explicitly not ignored
        }
        continue;
      }

      // Check if the path matches the pattern
      if (_matchesGitignorePattern(normalizedPath, pattern)) {
        return true; // Ignored
      }
    }

    return false;
  }

  /// Check if a file path matches a specific gitignore pattern
  bool _matchesGitignorePattern(String filePath, String pattern) {
    // Normalize the pattern
    var normalizedPattern = pattern.trim().replaceAll('\\', '/');

    // Handle directory-only patterns (ending with /)
    final dirOnly = normalizedPattern.endsWith('/');
    if (dirOnly) {
      normalizedPattern =
          normalizedPattern.substring(0, normalizedPattern.length - 1);
    }

    // Convert gitignore glob pattern to RegExp
    String regexPattern = normalizedPattern
        .replaceAll('.', '\\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.')
        .replaceAll('/', '\\/');

    // Handle patterns with no slashes (match anywhere in path)
    if (!normalizedPattern.contains('/')) {
      regexPattern = '.*$regexPattern';
    }

    // Handle patterns starting with / (match from root)
    else if (normalizedPattern.startsWith('/')) {
      regexPattern = '^${regexPattern.substring(1)}';
    }

    // Create the RegExp and test the path
    try {
      final regex = RegExp(regexPattern);
      return regex.hasMatch(filePath);
    } catch (e) {
      print('Error in gitignore pattern matching: $e');
      // Fall back to simple contains check
      return filePath.contains(normalizedPattern);
    }
  }

  // Note: The _uploadFileToRepo method has been replaced by the more efficient batch upload approach using GitHub's Git Data API
}
