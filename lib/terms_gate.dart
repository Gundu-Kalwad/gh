import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that shows a one-time Terms and Conditions popup.
/// If the user disagrees, the app closes. If the user agrees, the dialog is never shown again.
class TermsGate extends StatefulWidget {
  final Widget child;
  const TermsGate({required this.child, Key? key}) : super(key: key);

  @override
  State<TermsGate> createState() => _TermsGateState();
}

class _TermsGateState extends State<TermsGate> {
  bool _agreed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkAgreement();
  }

  Future<void> _checkAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreed_terms') ?? false;
    if (!agreed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTermsDialog());
    }
    setState(() {
      _agreed = agreed;
      _checked = true;
    });
  }

  Future<void> _showTermsDialog() async {
    bool agreed = false;
    while (!agreed && mounted) {
      agreed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            barrierColor:
                const Color(0xFF181A20), // Match app's scaffold background
            builder: (context) => Stack(
              children: [
                // Background with app name and greetings
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF23262F).withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.code,
                                    color: Color(0xFF64FFDA), size: 28),
                                SizedBox(height: 6),
                                Text(
                                  'Welcome to',
                                  style: TextStyle(
                                    color: Color(0xFF64FFDA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Pro Coding Studio',
                                  style: TextStyle(
                                    color: Color(0xFF64FFDA),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    letterSpacing: 1.1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Fix overflow: Wrap in SafeArea and use Flexible
                      SafeArea(
                        minimum: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF23262F).withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Happy coding! - Team Pro Coding Studio',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                // The popup dialog
                Center(
                  child: Dialog(
                    backgroundColor: const Color(0xFF23262F),
                    insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user,
                                size: 56, color: Color(0xFF64FFDA)),
                            const SizedBox(height: 18),
                            const Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'By accepting, you agree to our Terms and Conditions. Please review them before proceeding.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final url = Uri.parse(
                                    'https://youtube.com/@developerprajwalsingh?si=h01tvKzeqHJa7qED');
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF23262F),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Color(0xFF64FFDA), width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.open_in_new,
                                        color: Color(0xFF64FFDA), size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'View Terms and Conditions',
                                        style: TextStyle(
                                          color: Color(0xFF64FFDA),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.redAccent, width: 2),
                                      foregroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text('Disagree'),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF64FFDA),
                                      foregroundColor: Color(0xFF23262F),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!agreed) {
        // Close the app if user disagrees
        await SystemNavigator.pop();
      }
    }
    if (agreed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('agreed_terms', true);
      setState(() {
        _agreed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox.shrink();
    if (!_agreed) return const SizedBox.shrink();
    return widget.child;
  }
}
