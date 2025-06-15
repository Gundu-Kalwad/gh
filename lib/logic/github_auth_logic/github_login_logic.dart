import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'github_login_token.dart';

// Add provider to track auth state
final githubAuthStateProvider =
    StateProvider<GitHubAuthState>((ref) => GitHubAuthState.idle);

enum GitHubAuthState {
  idle,
  requesting,
  waitingForUser,
  success,
  failed,
}

class GitHubAuth {
  final String clientId = "Ov23liOWQ1iHM3LoqL6x";
  final String scope = "repo workflow read:user";
  String? _deviceCode;
  int _interval = 5;
  Timer? _pollingTimer;
  bool _isPolling = false;
  final DateTime _startTime = DateTime.now();
  static const int _deviceCodeExpiresIn = 900; // 15 minutes (GitHub default)

  // Use this method from the More panel
  Future<void> login(WidgetRef ref) async {
    // Update state
    ref.read(githubAuthStateProvider.notifier).state =
        GitHubAuthState.requesting;

    final response = await http.post(
      Uri.parse("https://github.com/login/device/code"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: "client_id=$clientId&scope=${Uri.encodeComponent(scope)}",
    );

    final data = Uri.splitQueryString(response.body);

    if (data["device_code"] != null) {
      _deviceCode = data["device_code"];
      _interval = int.parse(data["interval"]!);

      final userCode = data["user_code"];
      final verifyUrl = data["verification_uri"];

      // Update state
      ref.read(githubAuthStateProvider.notifier).state =
          GitHubAuthState.waitingForUser;

      // Show user dialogue with instructions
      showGitHubAuthDialog(userCode, verifyUrl, ref);

      // Launch GitHub verification page
      if (verifyUrl != null) {
        await launchUrl(Uri.parse(verifyUrl),
            mode: LaunchMode.externalApplication);
        // Auto-copy code to clipboard
        await Clipboard.setData(ClipboardData(text: userCode ?? ""));
        debugPrint("Copied code to clipboard: $userCode");
      } else {
        debugPrint("Error: Missing verification_uri in response.");
        ref.read(githubAuthStateProvider.notifier).state =
            GitHubAuthState.failed;
        return;
      }

      // Start polling for access token
      startPollingForToken(ref);
    } else {
      debugPrint("Error: ${data["error_description"]}");
      ref.read(githubAuthStateProvider.notifier).state = GitHubAuthState.failed;
    }
  }

  void startPollingForToken(WidgetRef ref) {
    if (_isPolling) return;
    _isPolling = true;

    _pollingTimer = Timer.periodic(Duration(seconds: _interval), (_) {
      checkForAccessToken(ref);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  Future<void> checkForAccessToken(WidgetRef ref) async {
    if (_deviceCode == null) return;

    // Check if device code has expired
    if (DateTime.now().difference(_startTime).inSeconds >
        _deviceCodeExpiresIn) {
      debugPrint("Polling timed out.");
      stopPolling();
      ref.read(githubAuthStateProvider.notifier).state = GitHubAuthState.failed;
      return;
    }

    try {
      final tokenUrl = 'https://github.com/login/oauth/access_token';
      final res = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        body:
            "client_id=$clientId&device_code=$_deviceCode&grant_type=urn:ietf:params:oauth:grant-type:device_code",
      );

      final tokenData = json.decode(res.body);

      if (tokenData["access_token"] != null) {
        final token = tokenData["access_token"];
        debugPrint("GitHub Access Token received");

        // Call handleGitHubLogin to save token and update state
        await handleGitHubLogin(ref, token);

        stopPolling();
        ref.read(githubAuthStateProvider.notifier).state =
            GitHubAuthState.success;
      } else if (tokenData["error"] == "authorization_pending") {
        debugPrint("Waiting for user authorization...");
      } else if (tokenData["error"] == "slow_down") {
        debugPrint("GitHub asked to slow down polling, increasing interval.");
        _interval += 5;
        stopPolling(); // Reset the timer with new interval
        startPollingForToken(ref);
      } else if (tokenData["error"] == "expired_token") {
        debugPrint(
            "Device code expired. Please start the login process again.");
        stopPolling();
        ref.read(githubAuthStateProvider.notifier).state =
            GitHubAuthState.failed;
      } else if (tokenData["error"] == "access_denied") {
        debugPrint("User denied access.");
        stopPolling();
        ref.read(githubAuthStateProvider.notifier).state =
            GitHubAuthState.failed;
      } else {
        debugPrint(
            "Error: ${tokenData["error_description"] ?? tokenData["error"]}");
        stopPolling();
        ref.read(githubAuthStateProvider.notifier).state =
            GitHubAuthState.failed;
      }
    } catch (e) {
      debugPrint("Network error during polling: $e");
      // Don't stop polling on network errors, just try again next interval
    }
  }

  // Helper method to display a dialog with instructions
  void showGitHubAuthDialog(
      String? userCode, String? verifyUrl, WidgetRef ref) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23262F),
          title: const Text('GitHub Authentication',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Complete GitHub authorization in your browser. Use this code:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF181A20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF64FFDA)),
                ),
                child: SelectableText(
                  userCode ?? '',
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The code has been copied to your clipboard.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                stopPolling();
                ref.read(githubAuthStateProvider.notifier).state =
                    GitHubAuthState.idle;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Try Again',
                  style: TextStyle(color: Color(0xFF64FFDA))),
              onPressed: () async {
                Navigator.of(context).pop();
                if (verifyUrl != null) {
                  await launchUrl(Uri.parse(verifyUrl),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
