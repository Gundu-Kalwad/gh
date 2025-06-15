import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Provider for cookie consent status
final cookieConsentProvider = StateProvider<bool?>((ref) => null);

/// Dialog to ask for cookie consent
class CookieConsentDialog extends ConsumerWidget {
  const CookieConsentDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: const Color(0xFF23262F),
      title: const Text(
        'Cookie Consent',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pro Coding Studio would like to store cookies for the AI Assistant browser to keep you logged in.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'This will allow you to remain logged in to any AI service you use in the browser (e.g., ChatGPT, Gemini, etc.) between sessions.',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'You can change this setting later in the app preferences.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // User declined cookie storage
            _saveCookiePreference(false, ref);
            Navigator.of(context).pop(false);
          },
          child: const Text(
            'Decline',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            // User accepted cookie storage
            _saveCookiePreference(true, ref);
            Navigator.of(context).pop(true);
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }

  // Save cookie preference to secure storage
  Future<void> _saveCookiePreference(bool consent, WidgetRef ref) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'cookie_consent', value: consent.toString());
    ref.read(cookieConsentProvider.notifier).state = consent;
  }
}

/// Check if user has given cookie consent
Future<bool?> checkCookieConsent(WidgetRef ref) async {
  const storage = FlutterSecureStorage();
  final consentString = await storage.read(key: 'cookie_consent');

  if (consentString != null) {
    final consent = consentString == 'true';
    ref.read(cookieConsentProvider.notifier).state = consent;
    return consent;
  }

  return null; // No preference set yet
}
