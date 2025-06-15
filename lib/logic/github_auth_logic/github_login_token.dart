import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final storage = const FlutterSecureStorage();

final githubTokenProvider = StateProvider<String?>((ref) => null);
final githubUsernameProvider = StateProvider<String?>((ref) => null);
final githubConnectedProvider = StateProvider<bool>((ref) => false);

Future<void> handleGitHubLogin(WidgetRef ref, String accessToken) async {
  try {
    // Step 1: Fetch user info from GitHub
    final response = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      final username = userData['login'];

      // Step 2: Save access token and username securely
      await storage.write(key: 'github_token', value: accessToken);
      await storage.write(key: 'github_username', value: username);
      await storage.write(key: 'github_connected', value: 'true');

      debugPrint('GitHub token and username saved securely.');

      // Update Riverpod providers
      ref.read(githubTokenProvider.notifier).state = accessToken;
      ref.read(githubUsernameProvider.notifier).state = username;
      ref.read(githubConnectedProvider.notifier).state = true;

      debugPrint('GitHub connected as @$username');
    } else {
      debugPrint(
          'Failed to fetch user info from GitHub: Status: ${response.statusCode} Body: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
