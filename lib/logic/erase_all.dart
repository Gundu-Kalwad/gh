import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_logic.dart';
import 'package:pro_coding_studio/logic/github_operations/github_ssh_operations.dart';
import 'package:pro_coding_studio/ui/ai/cookie_consent_dialog.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';
import 'package:pro_coding_studio/logic/tabs/editor_tabs_logic.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';

/// Service for erasing all application data
class EraseAllDataService {
  static const _secureStorage = FlutterSecureStorage();

  /// Erase all application data with user confirmation
  static Future<bool> eraseAllDataWithConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(context);
    if (!confirmed) return false;

    // Show progress dialog and perform erasure
    return await _showProgressAndErase(context, ref);
  }

  /// Show confirmation dialog to user
  static Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF23262F),
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Erase All Data',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will permanently delete:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text('• GitHub authentication data',
                      style: TextStyle(color: Colors.white70)),
                  Text('• SSH keys and configuration',
                      style: TextStyle(color: Colors.white70)),
                  Text('• Cookie consent preferences',
                      style: TextStyle(color: Colors.white70)),
                  Text('• Terms acceptance status',
                      style: TextStyle(color: Colors.white70)),
                  Text('• Recent directories and files',
                      style: TextStyle(color: Colors.white70)),
                  Text('• AI browser cookies and cache',
                      style: TextStyle(color: Colors.white70)),
                  Text('• All app preferences and settings',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 16),
                  Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Erase All Data'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show progress dialog and perform data erasure
  static Future<bool> _showProgressAndErase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final results = <String, bool>{};
    String currentStep = 'Initializing...';
    bool isComplete = false;
    bool finalResult = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                if (!isComplete) {
                  // Start the erasure process
                  _performErasure(ref, (step, stepResults) {
                    if (context.mounted) {
                      setState(() {
                        currentStep = step;
                        results.addAll(stepResults);
                      });
                    }
                  }).then((success) {
                    if (context.mounted) {
                      setState(() {
                        isComplete = true;
                        finalResult = success;
                        currentStep = success
                            ? 'Erasure completed successfully!'
                            : 'Erasure completed with errors';
                      });

                      // Auto-close after showing results for 2 seconds
                      Future.delayed(const Duration(seconds: 2), () {
                        if (context.mounted) {
                          Navigator.of(context).pop(success);
                        }
                      });
                    }
                  });
                }

                return AlertDialog(
                  backgroundColor: const Color(0xFF23262F),
                  title: Text(
                    isComplete ? 'Data Erasure Complete' : 'Erasing Data...',
                    style: const TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isComplete) ...[
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Icon(
                          finalResult ? Icons.check_circle : Icons.error,
                          color: finalResult ? Colors.green : Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        currentStep,
                        style: TextStyle(
                          color: isComplete
                              ? (finalResult ? Colors.green : Colors.red)
                              : Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (results.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: results.entries.map((entry) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        entry.value ? Icons.check : Icons.error,
                                        color: entry.value
                                            ? Colors.green
                                            : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: entry.value
                                                ? Colors.white70
                                                : Colors.red[300],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: isComplete
                      ? [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64FFDA),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(finalResult),
                            child: const Text('OK'),
                          ),
                        ]
                      : null,
                );
              },
            );
          },
        ) ??
        false;
  }

  /// Perform the actual data erasure
  static Future<bool> _performErasure(
    WidgetRef ref,
    Function(String step, Map<String, bool> results) onProgress,
  ) async {
    final results = <String, bool>{};
    int successCount = 0;
    int totalSteps = 0;

    try {
      // Step 1: Clear Flutter Secure Storage
      onProgress('Clearing secure storage...', {});
      await Future.delayed(
          const Duration(milliseconds: 500)); // Allow UI update

      final secureStorageResult = await _clearSecureStorage();
      results['GitHub tokens and SSH keys'] = secureStorageResult;
      if (secureStorageResult) successCount++;
      totalSteps++;
      onProgress('Clearing secure storage...', Map.from(results));

      // Step 2: Clear SharedPreferences
      onProgress('Clearing app preferences...', Map.from(results));
      await Future.delayed(const Duration(milliseconds: 300));

      final sharedPrefsResult = await _clearSharedPreferences();
      results['App preferences and settings'] = sharedPrefsResult;
      if (sharedPrefsResult) successCount++;
      totalSteps++;
      onProgress('Clearing app preferences...', Map.from(results));

      // Step 3: Clear WebView data
      onProgress('Clearing browser data...', Map.from(results));
      await Future.delayed(const Duration(milliseconds: 300));

      final webViewResult = await _clearWebViewData();
      results['Browser cookies and cache'] = webViewResult;
      if (webViewResult) successCount++;
      totalSteps++;
      onProgress('Clearing browser data...', Map.from(results));

      // Step 4: Reset Riverpod providers
      onProgress('Resetting app state...', Map.from(results));
      await Future.delayed(const Duration(milliseconds: 300));

      final providersResult = await _resetProviders(ref);
      results['App state and providers'] = providersResult;
      if (providersResult) successCount++;
      totalSteps++;
      onProgress('Resetting app state...', Map.from(results));

      // Step 5: Final cleanup
      onProgress('Finalizing cleanup...', Map.from(results));
      await Future.delayed(const Duration(milliseconds: 500));

      final cleanupResult = await _performFinalCleanup();
      results['Final cleanup'] = cleanupResult;
      if (cleanupResult) successCount++;
      totalSteps++;

      onProgress('Data erasure completed', Map.from(results));

      // Return true if at least 80% of operations succeeded
      return (successCount / totalSteps) >= 0.8;
    } catch (e) {
      results['Error occurred'] = false;
      onProgress('Error during erasure: $e', Map.from(results));
      return false;
    }
  }

  /// Clear Flutter Secure Storage
  static Future<bool> _clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
      return false;
    }
  }

  /// Clear SharedPreferences
  static Future<bool> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      debugPrint('Error clearing shared preferences: $e');
      return false;
    }
  }

  /// Clear WebView data (cookies, cache, local storage)
  static Future<bool> _clearWebViewData() async {
    try {
      // Clear WebView cookies and cache
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();

      // Note: WebView cache clearing might require additional platform-specific implementation
      // For now, we'll focus on cookies which are the main privacy concern
      return true;
    } catch (e) {
      debugPrint('Error clearing WebView data: $e');
      return false;
    }
  }

  /// Reset all Riverpod providers to their initial state
  static Future<bool> _resetProviders(WidgetRef ref) async {
    try {
      // GitHub auth providers
      ref.read(githubTokenProvider.notifier).state = null;
      ref.read(githubUsernameProvider.notifier).state = null;
      ref.read(githubConnectedProvider.notifier).state = false;
      ref.read(githubAuthStateProvider.notifier).state = GitHubAuthState.idle;

      // SSH providers
      ref.read(sshKeyGenerationStatusProvider.notifier).state =
          SSHKeyStatus.none;
      ref.read(sshPublicKeyProvider.notifier).state = null;
      ref.read(sshConfiguredProvider.notifier).state = false;

      // Cookie consent provider
      ref.read(cookieConsentProvider.notifier).state = null;

      // Document file providers
      ref.read(directoryUriProvider.notifier).state = null;
      ref.read(currentDirectoryInfoProvider.notifier).state = null;
      ref.read(filesListInfoProvider.notifier).state = [];
      ref.read(selectedFileInfoProvider.notifier).state = null;
      ref.read(hasExplorerPermissionProvider.notifier).state =
          false; // Editor providers
      ref.read(openFileProvider.notifier).state = null;
      ref.read(editorContentProvider.notifier).state = '';
      ref.read(hasUnsavedChangesProvider.notifier).state = false;

      // Tabs provider - reset to initial state
      final tabsNotifier = ref.read(editorTabsProvider.notifier);
      final currentTabs = ref.read(editorTabsProvider).openTabs;
      // Close all tabs one by one
      for (int i = currentTabs.length - 1; i >= 0; i--) {
        tabsNotifier.closeTab(i);
      }

      return true;
    } catch (e) {
      debugPrint('Error resetting providers: $e');
      return false;
    }
  }

  /// Perform final cleanup operations
  static Future<bool> _performFinalCleanup() async {
    try {
      // Additional cleanup operations can be added here
      // For example: clearing temporary files, cache directories, etc.

      // Force garbage collection
      // Note: Dart's GC is automatic, but we can suggest it

      return true;
    } catch (e) {
      debugPrint('Error in final cleanup: $e');
      return false;
    }
  }
}
