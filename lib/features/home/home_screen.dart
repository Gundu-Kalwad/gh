import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ocr_scanner/ocr_scanner_screen.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import '../text_to_pdf/text_to_pdf_screen.dart';
import '../voice_to_pdf/voice_to_pdf_screen.dart';
import '../images_to_pdf/images_to_pdf_screen.dart';

import '../zip_to_pdf/zip_to_pdf_screen.dart';
import '../edit_pdf/edit_pdf_screen.dart';
import '../web_to_pdf/web_to_pdf_screen.dart';

import '../../providers/pdf_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Image.asset(
            'assets/logo_image.png',
            height: 35,
            width: 35,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.picture_as_pdf, size: 28, color: Colors.white70),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (Rect bounds) => const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFFFF6A00), Color(0xFFFFC371), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Hello PDF',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: 1.2,
              // color intentionally omitted for gradient
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Settings',
              splashRadius: 26,
              color: Colors.blue.shade900,
              onPressed: () => _showSettingsDialog(context, ref),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7), Color(0xFF1FA2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Hero Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 44, color: Color(0xFF8EC5FC)),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Welcome to Hello PDF!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B3B3B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All-in-one PDF toolbox: create, edit, scan, convert, and organize your PDFs with ease.',
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Features Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 1.03,
                      children: [
                        _buildModernFeatureCard(
                          context,
                          'My PDFs',
                          Icons.folder,
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PdfViewerScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'Images to PDF',
                          Icons.image,
                          Colors.blueAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImagesToPdfScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'Text to PDF',
                          Icons.text_fields,
                          Colors.teal,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TextToPdfScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'Voice to PDF',
                          Icons.mic,
                          Colors.deepPurple,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoiceToPdfScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'OCR Scan',
                          Icons.camera_alt,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OcrScannerScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'Web to PDF',
                          Icons.language,
                          Colors.indigo,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WebToPdfScreen(),
                            ),
                          ),
                        ),
                        _buildModernFeatureCard(
                          context,
                          'Edit PDF',
                          Icons.edit,
                          Colors.redAccent,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditPdfScreen(),
                            ),
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeatureCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.08), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.18), color.withOpacity(0.07)]),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(18),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.85),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.mail_outline, color: Colors.blue),
                title: const Text('Contact Us'),
                onTap: () async {
                  try {
                    final email = 'srk.apps88@gmail.com';
                    final subject = 'Hello PDF Support';
                    final body = 'Hello!\n\nI have a question about Hello PDF:\n\n';
                    
                    // Try Gmail app first
                    if (await url_launcher.canLaunchUrl(Uri.parse('mailto:$email'))) {
                      await url_launcher.launchUrl(
                        Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'),
                        mode: url_launcher.LaunchMode.externalApplication,
                      );
                    } else {
                      // Fallback to default email app
                      await url_launcher.launchUrl(
                        Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}'),
                        mode: url_launcher.LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open email app. Please check if you have an email app installed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                title: const Text('About'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('About'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('App Name: Hello PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Version: 13.0.0'),
                          SizedBox(height: 8),
                          Text('Developed by: SRK Apps.'),
                          SizedBox(height: 16),
                          Text('All-in-one PDF toolbox: create, edit, scan, convert, and organize your PDFs with ease.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All PDFs'),
        content: const Text('Are you sure you want to delete all PDFs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(pdfListProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All PDFs cleared successfully'),
                ),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
