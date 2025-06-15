import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:pro_coding_studio/ui/ai/ai_resource.dart';
import 'package:pro_coding_studio/ui/ai/cookie_consent_dialog.dart';

/// AI Resources drawer that slides from right to left
class AIDrawer extends ConsumerStatefulWidget {
  const AIDrawer({Key? key}) : super(key: key);

  @override
  AIDrawerState createState() => AIDrawerState();
}

class AIDrawerState extends ConsumerState<AIDrawer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool?>(
      future: checkCookieConsent(ref),
      builder: (context, snapshot) {
        final consent = snapshot.data;
        if (consent == null) {
          // Show consent dialog before anything else
          return const CookieConsentDialog();
        }
        // Only show the AI drawer if consent is given or declined
        return _AIDrawerContent(cookieConsent: consent);
      },
    );
  }
}

class _AIDrawerContent extends ConsumerStatefulWidget {
  final bool cookieConsent;
  const _AIDrawerContent({required this.cookieConsent, Key? key})
      : super(key: key);

  @override
  ConsumerState<_AIDrawerContent> createState() => _AIDrawerContentState();
}

class _AIDrawerContentState extends ConsumerState<_AIDrawerContent> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _showWebView = false;
  String _currentUrl = '';
  String _currentTitle = '';

  // List of AI resources that can help with coding
  final List<AIResource> _aiResources = [
    const AIResource(
      name: 'ChatGPT',
      description: 'AI assistant for coding help, debugging, and explanations',
      url: 'https://chat.openai.com/',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF10A37F),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Gemini',
      description: 'Google AI for code generation and problem-solving',
      url: 'https://gemini.google.com/',
      icon: Icons.auto_awesome,
      color: Color(0xFF1A73E8),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Perplexity',
      description: 'AI search engine with coding examples and documentation',
      url: 'https://www.perplexity.ai/',
      icon: Icons.search,
      color: Color(0xFF5436DA),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Claude',
      description: 'Anthropic AI assistant with strong coding capabilities',
      url: 'https://claude.ai/',
      icon: Icons.psychology,
      color: Color(0xFFFF8C00),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'GitHub Copilot',
      description: 'AI pair programmer (requires subscription)',
      url: 'https://github.com/features/copilot',
      icon: Icons.code,
      color: Color(0xFF0D1117),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'BlackBox AI',
      description: 'Code completion and generation tool',
      url: 'https://www.useblackbox.io/',
      icon: Icons.code_rounded,
      color: Color(0xFF121212),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Meta AI',
      description: 'Meta AI assistant for coding and general tasks',
      url: 'https://meta.ai/',
      icon: Icons.public,
      color: Color(0xFF0668E1),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Stack Overflow',
      description: 'Community Q&A for programming problems',
      url: 'https://stackoverflow.com/',
      icon: Icons.question_answer,
      color: Color(0xFFF48024),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Hugging Face',
      description: 'Open source AI models and tools',
      url: 'https://huggingface.co/',
      icon: Icons.auto_awesome,
      color: Color(0xFFFFD21E),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'Replit Ghostwriter',
      description: 'AI coding assistant integrated with online IDE',
      url: 'https://replit.com/site/ghostwriter',
      icon: Icons.terminal,
      color: Color(0xFFF26207),
      needsExternalBrowser: false,
    ),
    const AIResource(
      name: 'MDN Web Docs',
      description: 'Comprehensive web development documentation',
      url: 'https://developer.mozilla.org/',
      icon: Icons.web,
      color: Color(0xFF83D0F2),
      needsExternalBrowser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize WebView controller with enhanced settings
    _controller = WebViewController()
      // Enable JavaScript for all AI tools
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Set background color to match app theme
      ..setBackgroundColor(const Color(0xFF181A20))
      // Set a desktop user agent to get full versions of sites
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36')
      // Enable zoom for better reading
      ..enableZoom(true)
      // Set navigation delegate for loading indicators and error handling
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Improve mobile viewing experience
            _improveWebViewDisplay();
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            // Show error in UI if needed
          },
        ),
      );
    if (!widget.cookieConsent) {
      // If user declined cookies, clear cookies for WebView
      _controller.clearCache();
      // Optionally, you can use incognito mode if supported
    }
  }

  // Open a URL in the internal WebView
  void _openInWebView(String url, String title) {
    setState(() {
      _showWebView = true;
      _currentUrl = url;
      _currentTitle = title;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(url));
  }

  // Open a URL in the external browser
  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri,
          mode: url_launcher.LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  // Handle resource tap based on whether it needs external browser
  void _handleResourceTap(AIResource resource) {
    if (resource.needsExternalBrowser) {
      _openInBrowser(resource.url);
    } else {
      _openInWebView(resource.url, resource.name);
    }
  }

  // Go back to the resource list
  void _backToResourceList() {
    setState(() {
      _showWebView = false;
    });
  }

  // Improve the WebView display for better mobile viewing
  Future<void> _improveWebViewDisplay() async {
    // Inject JavaScript to improve the display of websites on mobile
    await _controller.runJavaScript('''
      // Add viewport meta tag if not present
      if (!document.querySelector('meta[name="viewport"]')) {
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0';
        document.getElementsByTagName('head')[0].appendChild(meta);
      }
      
      // Add custom styles for better readability
      var style = document.createElement('style');
      style.textContent = `
        body { font-size: 16px !important; }
        input, select, textarea { font-size: 16px !important; }
      `;
      document.head.appendChild(style);
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent overlay for the rest of the screen
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black54),
            ),
          ),
          // Actual drawer content
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Color(0xFF23262F),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF181A20),
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFF2F3341), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_showWebView)
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white70),
                              onPressed: _backToResourceList,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _showWebView
                                      ? _currentTitle
                                      : 'AI Resources (mini Browser)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const Text(
                                  'Coding assistance tools',
                                  style: TextStyle(
                                    color: Color(0xFF64FFDA),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showWebView)
                            IconButton(
                              icon: const Icon(Icons.open_in_browser,
                                  color: Color(0xFF64FFDA)),
                              onPressed: () => _openInBrowser(_currentUrl),
                              tooltip: 'Open in external browser',
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          if (_showWebView)
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Color(0xFF64FFDA)),
                              onPressed: () => _controller.reload(),
                              iconSize: 20,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: Colors.white70),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            iconSize: 20,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Content - either WebView or resource list
                    Expanded(
                      child: _showWebView
                          ? Stack(
                              children: [
                                WebViewWidget(controller: _controller),
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF64FFDA),
                                    ),
                                  ),
                              ],
                            )
                          : _buildResourceList(),
                    ),

                    // Disclaimer
                    if (!_showWebView)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: const Color(0xFF181A20),
                        child: const Text(
                          'External services are subject to their respective terms of service and privacy policies.',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the resource list view
  Widget _buildResourceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _aiResources.length,
      itemBuilder: (context, index) {
        final resource = _aiResources[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF2F3341),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: resource.color,
              child: Icon(resource.icon, color: Colors.white),
            ),
            title: Text(
              resource.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              resource.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: Icon(
              resource.needsExternalBrowser
                  ? Icons.open_in_new
                  : Icons.arrow_forward,
              color: const Color(0xFF64FFDA),
              size: 18,
            ),
            onTap: () => _handleResourceTap(resource),
          ),
        );
      },
    );
  }
}
