import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/editor_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logic/github_auth_logic/github_login_logic.dart';
import 'logic/github_auth_logic/github_login_token.dart';
import 'terms_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final container = ProviderContainer();

  // Initialize GitHub login state from secure storage
  await initializeGitHubState(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

/// Initialize GitHub state from secure storage
Future<void> initializeGitHubState(ProviderContainer container) async {
  try {
    final token = await storage.read(key: 'github_token');
    final username = await storage.read(key: 'github_username');
    final connected = await storage.read(key: 'github_connected');

    if (token != null && username != null && connected == 'true') {
      // Update providers with stored values
      container.read(githubTokenProvider.notifier).state = token;
      container.read(githubUsernameProvider.notifier).state = username;
      container.read(githubConnectedProvider.notifier).state = true;
      container.read(githubAuthStateProvider.notifier).state =
          GitHubAuthState.success;

      debugPrint('GitHub authentication restored for user: $username');
    }
  } catch (e) {
    debugPrint('Error restoring GitHub authentication state: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Mobile Code Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF22242A),
          secondary: const Color(0xFF64FFDA),
          background: const Color(0xFF181A20),
        ),
        scaffoldBackgroundColor: const Color(0xFF181A20),
        fontFamily: 'FiraMono',
      ),
      home: TermsGate(child: const EditorScreen()),
    );
  }
}
