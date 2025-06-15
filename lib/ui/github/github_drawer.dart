import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_logic.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';
import 'package:pro_coding_studio/logic/github_operations/github_ssh_operations.dart';
import 'package:pro_coding_studio/logic/github_operations/github_repo_operations.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubDrawer extends ConsumerWidget {
  const GitHubDrawer({Key? key}) : super(key: key);

  // Show dialog to download a project from GitHub
  void _showDownloadProjectDialog(BuildContext context, WidgetRef ref) {
    final repoOperations = ref.read(githubRepoOperationsProvider);
    final TextEditingController ownerController = TextEditingController();
    final TextEditingController repoController = TextEditingController();
    final TextEditingController branchController =
        TextEditingController(text: 'main');

    // Get current directory URI
    final directoryUri = ref.read(directoryUriProvider);
    if (directoryUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please open a folder first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Watch download progress
          final progress = ref.watch(downloadProgressProvider);
          final message = ref.watch(repoOperationMessageProvider);

          return AlertDialog(
            backgroundColor: const Color(0xFF23262F),
            title: const Text('Download GitHub Project',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter the repository details to download:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ownerController,
                    decoration: const InputDecoration(
                      labelText: 'Repository Owner',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g., octocat',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: repoController,
                    decoration: const InputDecoration(
                      labelText: 'Repository Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g., hello-world',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: branchController,
                    decoration: const InputDecoration(
                      labelText: 'Branch (optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g., main',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: progress,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF64FFDA)),
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message ?? 'Downloading...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: Colors.black,
                ),
                onPressed: progress != null
                    ? null
                    : () async {
                        if (ownerController.text.isEmpty ||
                            repoController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please fill in all required fields')),
                          );
                          return;
                        }

                        final success =
                            await repoOperations.downloadProjectFromGitHub(
                          repoOwner: ownerController.text.trim(),
                          repoName: repoController.text.trim(),
                          branch: branchController.text.trim().isNotEmpty
                              ? branchController.text.trim()
                              : 'main',
                          targetDirectoryUri: directoryUri,
                        );

                        if (success && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Project downloaded successfully')),
                          );
                        }
                      },
                child: const Text('Download'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show dialog to upload the current project to GitHub
  void _showUploadProjectDialog(BuildContext context, WidgetRef ref) {
    final repoOperations = ref.read(githubRepoOperationsProvider);
    final TextEditingController repoNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isPrivate = false;

    // Get current directory URI
    final directoryUri = ref.read(directoryUriProvider);
    if (directoryUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please open a folder first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Watch upload progress
          final progress = ref.watch(uploadProgressProvider);
          final message = ref.watch(repoOperationMessageProvider);

          return AlertDialog(
            backgroundColor: const Color(0xFF23262F),
            title: const Text('Upload Project to GitHub',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a new GitHub repository and upload the current project:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: repoNameController,
                    decoration: const InputDecoration(
                      labelText: 'Repository Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g., my-flutter-app',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'A short description of your project',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isPrivate,
                        onChanged: progress != null
                            ? null
                            : (value) {
                                setState(() {
                                  isPrivate = value ?? false;
                                });
                              },
                        activeColor: const Color(0xFF64FFDA),
                      ),
                      const Text(
                        'Private Repository',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: progress,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF64FFDA)),
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message ?? 'Uploading...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: Colors.black,
                ),
                onPressed: progress != null
                    ? null
                    : () async {
                        if (repoNameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please enter a repository name')),
                          );
                          return;
                        }

                        // Close the dialog as soon as we start the upload process
                        Navigator.of(context).pop();

                        // Start the upload process
                        final success =
                            await repoOperations.uploadProjectToGitHub(
                          repoName: repoNameController.text.trim(),
                          description: descriptionController.text.trim(),
                          isPrivate: isPrivate,
                          directoryUri: directoryUri,
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Project uploaded successfully')),
                          );
                        }
                      },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Show dialog to create a new GitHub repository
  void _showCreateRepoDialog(BuildContext context, WidgetRef ref) {
    final repoOperations = ref.read(githubRepoOperationsProvider);
    final TextEditingController repoNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF23262F),
            title: const Text('Create GitHub Repository',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a new empty GitHub repository:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: repoNameController,
                    decoration: const InputDecoration(
                      labelText: 'Repository Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'e.g., my-new-project',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'A short description of your project',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF64FFDA)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isPrivate,
                        onChanged: (value) {
                          setState(() {
                            isPrivate = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF64FFDA),
                      ),
                      const Text(
                        'Private Repository',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  if (repoNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a repository name')),
                    );
                    return;
                  }

                  final token = ref.read(githubTokenProvider);
                  if (token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('GitHub token not found. Please sign in.')),
                    );
                    return;
                  }

                  // Create a new repository directly using the GitHub API
                  final response = await http.post(
                    Uri.parse('https://api.github.com/user/repos'),
                    headers: {
                      'Authorization': 'token $token',
                      'Accept': 'application/vnd.github.v3+json',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'name': repoNameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'private': isPrivate,
                      'auto_init': false,
                    }),
                  );

                  Map<String, dynamic>? repo;
                  if (response.statusCode == 201) {
                    repo = jsonDecode(response.body) as Map<String, dynamic>;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Error creating repository: ${response.body}')),
                    );
                  }

                  if (repo != null && context.mounted) {
                    Navigator.of(context).pop();

                    // Show success message with repository URL
                    final repoUrl = repo['html_url'] as String?;
                    if (repoUrl != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF23262F),
                          title: const Text('Repository Created',
                              style: TextStyle(color: Colors.white)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your repository has been created successfully!',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () {
                                  launchUrl(Uri.parse(repoUrl),
                                      mode: LaunchMode.externalApplication);
                                },
                                child: Text(
                                  repoUrl,
                                  style: const TextStyle(
                                    color: Color(0xFF64FFDA),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Close',
                                  style: TextStyle(color: Colors.white70)),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64FFDA),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                launchUrl(Uri.parse(repoUrl),
                                    mode: LaunchMode.externalApplication);
                              },
                              child: const Text('Open in Browser'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Repository created successfully')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get GitHub authentication state
    final isConnected = ref.watch(githubConnectedProvider);
    final username = ref.watch(githubUsernameProvider);
    return Drawer(
      backgroundColor: const Color(0xFF23262F),
      child: Column(
        children: [
          // GitHub Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            color: const Color(0xFF22242A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/github.svg',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF64FFDA),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'GitHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage your repositories and build your apps',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // GitHub Login Status
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E2128),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64FFDA).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF64FFDA),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? '@$username' : 'Not signed in',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? 'GitHub account connected'
                          : 'Sign in to access your repositories',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // GitHub Actions
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Authentication Section
                _buildSectionHeader('Authentication'),
                _buildDrawerItem(
                  icon: isConnected ? Icons.logout : Icons.login,
                  title: isConnected ? 'Sign out' : 'Sign in',
                  onTap: () async {
                    if (isConnected) {
                      // Sign out
                      await storage.delete(key: 'github_token');
                      await storage.delete(key: 'github_username');
                      await storage.delete(key: 'github_connected');

                      // Update providers
                      ref.read(githubTokenProvider.notifier).state = null;
                      ref.read(githubUsernameProvider.notifier).state = null;
                      ref.read(githubConnectedProvider.notifier).state = false;
                      ref.read(githubAuthStateProvider.notifier).state =
                          GitHubAuthState.idle;
                    } else {
                      // Sign in using existing logic
                      final auth = GitHubAuth();
                      await auth.login(ref);
                    }
                    Navigator.pop(context);
                  },
                ),

                // Repository Section
                _buildSectionHeader('Repository'),
                _buildDrawerItem(
                  icon: Icons.cloud_download,
                  title: 'Download Project',
                  enabled: isConnected,
                  onTap: () {
                    Navigator.pop(context);
                    _showDownloadProjectDialog(context, ref);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.cloud_upload,
                  title: 'Upload Current Project',
                  enabled: isConnected,
                  onTap: () {
                    Navigator.pop(context);
                    _showUploadProjectDialog(context, ref);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_box,
                  title: 'Create Repository',
                  enabled: isConnected,
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateRepoDialog(context, ref);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.call_split,
                  title: 'Fork Repository',
                  enabled: isConnected,
                  // TODO: Implement repository forking
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                // Build Section
                _buildSectionHeader('Build & Deploy'),
                _buildDrawerItem(
                  icon: Icons.build,
                  title: 'Trigger Build',
                  // TODO: Implement build triggering
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.check_circle_outline,
                  title: 'Build Status',
                  // TODO: Implement build status checking
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Download Artifact',
                  // TODO: Implement artifact downloading
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                // Git Operations Section
                _buildSectionHeader('Git Operations'),
                _buildDrawerItem(
                  icon: Icons.cloud_upload,
                  title: 'Push Changes',
                  enabled: isConnected,
                  // TODO: Implement push changes
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.cloud_download_outlined,
                  title: 'Pull Changes',
                  enabled: isConnected,
                  // TODO: Implement pull changes
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.save,
                  title: 'Commit Changes',
                  enabled: isConnected,
                  // TODO: Implement commit changes
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.merge_type,
                  title: 'Branches',
                  enabled: isConnected,
                  // TODO: Implement branch management
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: 'View Commit History',
                  enabled: isConnected,
                  // TODO: Implement commit history viewing
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                // Collaboration Section
                _buildSectionHeader('Collaboration'),
                _buildDrawerItem(
                  icon: Icons.merge,
                  title: 'Pull Requests',
                  enabled: isConnected,
                  // TODO: Implement pull request management
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bug_report,
                  title: 'Issues',
                  enabled: isConnected,
                  // TODO: Implement issues management
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                ),

                // Settings Section
                _buildSectionHeader('Settings'),
                _buildDrawerItem(
                  icon: Icons.key,
                  title: 'Generate SSH Key',
                  enabled: isConnected,
                  onTap: () async {
                    // Generate SSH key
                    Navigator.pop(context);
                    _showSSHKeyGenerationDialog(context, ref);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'GitHub Settings',
                  enabled: isConnected,
                  onTap: () async {
                    // Open GitHub settings in browser
                    final Uri url =
                        Uri.parse('https://github.com/settings/profile');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Documentation',
                  onTap: () async {
                    // Open GitHub documentation in browser
                    final Uri url = Uri.parse('https://docs.github.com/en');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Bottom section with version info
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E2128),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GitHub Integration v1.0',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(20, 20),
                  ),
                  child: const Text(
                    'Help',
                    style: TextStyle(
                      color: Color(0xFF64FFDA),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64FFDA),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white24, height: 1),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? const Color(0xFF64FFDA) : Colors.white38,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontSize: 16,
        ),
      ),
      onTap: enabled ? onTap : null,
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      dense: true,
    );
  }

  void _showSSHKeyGenerationDialog(BuildContext context, WidgetRef ref) {
    // Initialize SSH configuration
    GitHubSSHOperations.initializeSSHConfiguration(ref);

    // Get the email before showing the dialog
    final email = ref.read(githubUsernameProvider) ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _SSHKeyGenerationDialog(email: email);
      },
    );
  }
}

/// A stateful dialog for SSH key generation to properly handle state
class _SSHKeyGenerationDialog extends ConsumerStatefulWidget {
  final String email;

  const _SSHKeyGenerationDialog({required this.email});

  @override
  _SSHKeyGenerationDialogState createState() => _SSHKeyGenerationDialogState();
}

class _SSHKeyGenerationDialogState
    extends ConsumerState<_SSHKeyGenerationDialog> {
  @override
  Widget build(BuildContext context) {
    // Watch SSH key generation status
    final sshStatus = ref.watch(sshKeyGenerationStatusProvider);
    final sshPublicKey = ref.watch(sshPublicKeyProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF23262F),
      title: const Text('SSH Key Management',
          style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sshStatus == SSHKeyStatus.none ||
                sshStatus == SSHKeyStatus.error) ...[
              const Text(
                'Generate an SSH key to securely connect to GitHub without password authentication.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64FFDA),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () async {
                  await GitHubSSHOperations.generateAndUploadSSHKey(
                      ref, widget.email);
                  setState(() {}); // Refresh dialog state
                },
                child: const Text('Generate SSH Key'),
              ),
            ],
            if (sshStatus == SSHKeyStatus.generating) ...[
              const Text(
                'Generating SSH key pair...',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64FFDA))),
            ],
            if (sshStatus == SSHKeyStatus.uploading) ...[
              const Text(
                'Uploading SSH key to GitHub...',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64FFDA))),
            ],
            if (sshStatus == SSHKeyStatus.generated ||
                sshStatus == SSHKeyStatus.uploaded) ...[
              const Text(
                'Your SSH key has been generated and uploaded to GitHub.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              if (sshPublicKey != null) ...[
                const Text(
                  'Public Key:',
                  style: TextStyle(
                      color: Color(0xFF64FFDA), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sshPublicKey.length > 60
                            ? '${sshPublicKey.substring(0, 60)}...'
                            : sshPublicKey,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: sshPublicKey));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('SSH key copied to clipboard')),
                              );
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF64FFDA)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Close', style: TextStyle(color: Colors.white70)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        if (sshStatus == SSHKeyStatus.generated ||
            sshStatus == SSHKeyStatus.uploaded)
          TextButton(
            child: const Text('View in GitHub',
                style: TextStyle(color: Color(0xFF64FFDA))),
            onPressed: () async {
              final Uri url = Uri.parse('https://github.com/settings/keys');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
      ],
    );
  }
}
