import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/github_auth_logic/github_login_token.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro_coding_studio/logic/erase_all.dart';

/// A right-to-left sliding panel for the "More" button.
class MorePanel extends ConsumerWidget {
  final VoidCallback? onClose;
  const MorePanel({Key? key, this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(githubAuthStateProvider);
    final isConnected = ref.watch(githubConnectedProvider);
    final username = ref.watch(githubUsernameProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF23262F),
          borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 16,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed:
                        onClose ?? () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isConnected && username != null) ...[
                      // Display connected status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181A20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF64FFDA).withOpacity(0.5)),
                        ),
                        child: Column(
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
                                Expanded(
                                  child: Text(
                                    'Connected to GitHub',
                                    style: const TextStyle(
                                      color: Color(0xFF64FFDA),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '@$username',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // GitHub Sign In/Out buttons
                    if (!isConnected) ...[
                      // GitHub Sign In Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: authState == GitHubAuthState.requesting ||
                                authState == GitHubAuthState.waitingForUser
                            ? null
                            : () async {
                                await GitHubAuth().login(ref);
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authState == GitHubAuthState.requesting ||
                                authState ==
                                    GitHubAuthState.waitingForUser) ...[
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black54),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ] else ...[
                              SvgPicture.asset(
                                'assets/icons/github.svg',
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              authState == GitHubAuthState.waitingForUser
                                  ? 'Waiting for authorization...'
                                  : authState == GitHubAuthState.requesting
                                      ? 'Requesting access...'
                                      : 'GitHub Sign In',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // GitHub Sign Out Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          // Sign out logic
                          await storage.delete(key: 'github_token');
                          await storage.delete(key: 'github_username');
                          await storage.delete(key: 'github_connected');

                          ref.read(githubTokenProvider.notifier).state = null;
                          ref.read(githubUsernameProvider.notifier).state =
                              null;
                          ref.read(githubConnectedProvider.notifier).state =
                              false;
                          ref.read(githubAuthStateProvider.notifier).state =
                              GitHubAuthState.idle;
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/github.svg',
                              width: 22,
                              height: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'GitHub Sign Out',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Terms and Conditions button
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final url = Uri.parse(
                            'https://youtube.com/@developerprajwalsingh?si=h01tvKzeqHJa7qED');
                        // Use url_launcher to open the link
                        // ignore: deprecated_member_use
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      },
                      child: const Text(
                        'Terms and Condition',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Erase All Data button
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        // Call the erase all data service
                        await EraseAllDataService.eraseAllDataWithConfirmation(
                          context,
                          ref,
                        );

                        // Close the more panel after the operation
                        if (context.mounted) {
                          final closeCallback = onClose;
                          if (closeCallback != null) {
                            closeCallback();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        }
                      },
                      child: const Text(
                        'Erase All Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
