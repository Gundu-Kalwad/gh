import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';
import 'package:pro_coding_studio/logic/explorer/document_file_logic.dart';
import 'package:pro_coding_studio/ui/toolbar/menu_drawer_popup.dart';
import 'package:pro_coding_studio/ui/template/template_manager.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/all.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class EditorTextField extends ConsumerStatefulWidget {
  const EditorTextField({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends ConsumerState<EditorTextField> {
  CodeController? get exposedController => _controller;

  CodeController? _controller;
  String? _lastOpenFile;

  @override
  void initState() {
    super.initState();
    final openFile = ref.read(openFileProvider);
    final content = ref.read(editorContentProvider);
    _lastOpenFile = openFile;
    if (openFile != null) {
      _controller = _createController(content, openFile);
    }
  }

  @override
  void didUpdateWidget(covariant EditorTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final openFile = ref.read(openFileProvider);
    final content = ref.read(editorContentProvider);
    if (openFile != _lastOpenFile) {
      _lastOpenFile = openFile;
      _controller?.dispose();
      if (openFile != null) {
        _controller = _createController(content, openFile);
      } else {
        _controller = null;
      }
      setState(() {});
    }
  }

  CodeController _createController(String text, String? fileName) {
    return CodeController(
      text: text,
      language: _getLanguage(fileName),
    );
  }

  dynamic _getLanguage(String? fileName) {
    if (fileName == null) return allLanguages['dart'];
    // Extract extension
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    // Map of common aliases/extensions to highlight language keys (no duplicates)
    final extensionToLang = {
      'js': 'javascript',
      'ts': 'typescript',
      'c++': 'cpp',
      'c': 'c',
      'h': 'cpp',
      'hpp': 'cpp',
      'cc': 'cpp',
      'cs': 'csharp',
      'py': 'python',
      'rb': 'ruby',
      'kt': 'kotlin',
      'swift': 'swift',
      'go': 'go',
      'php': 'php',
      'rs': 'rust',
      'sh': 'bash',
      'bash': 'bash',
      'zsh': 'bash',
      'java': 'java',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'xml': 'xml',
      'html': 'xml',
      'css': 'css',
      'scss': 'scss',
      'less': 'less',
      'dart': 'dart',
      'sql': 'sql',
      'md': 'markdown',
      'markdown': 'markdown',
      'ini': 'ini',
      'toml': 'toml',
      'lua': 'lua',
      'pl': 'perl',
      'scala': 'scala',
      'vb': 'vbnet',
      'vue': 'vue',
      'coffee': 'coffeescript',
      'dockerfile': 'dockerfile',
      'makefile': 'makefile',
      'bat': 'dos',
      'asm': 'x86asm',
      'r': 'r',
      'tex': 'latex',
      'clj': 'clojure',
      'groovy': 'groovy',
      'erl': 'erlang',
      'elm': 'elm',
      'objective-c': 'objectivec',
      'm': 'objectivec',
      'fs': 'fsharp',
      'ml': 'ocaml',
      'ps1': 'powershell',
      'psm1': 'powershell',
      'psd1': 'powershell',
      'matlab': 'matlab',
      'octave': 'matlab',
      'sas': 'sas',
      'stata': 'stata',
      'jl': 'julia',
      'applescript': 'applescript',
      'cr': 'crystal',
      'nim': 'nim',
      'ada': 'ada',
      'd': 'd',
      'f90': 'fortran',
      'f95': 'fortran',
      'for': 'fortran',
      'f': 'fortran',
      'prolog': 'prolog',
      'lisp': 'lisp',
      'scm': 'scheme',
      'rkt': 'scheme',
      'tcl': 'tcl',
      'vhdl': 'vhdl',
      'verilog': 'verilog',
      'sv': 'verilog',
      'abap': 'abap',
      'awk': 'awk',
      'basic': 'basic',
      'brainfuck': 'brainfuck',
      'coq': 'coq',
      'diff': 'diff',
      'docker': 'dockerfile',
      'dot': 'dot',
      'gcode': 'gcode',
      'haskell': 'haskell',
      'json5': 'json',
      'nginx': 'nginx',
      'protobuf': 'protobuf',
      'sol': 'solidity',
      'sml': 'sml',
      'vala': 'vala',
    };
    final langKey = extensionToLang[ext] ?? ext;
    if (allLanguages.containsKey(langKey)) {
      return allLanguages[langKey];
    }
    // fallback to plain text (no highlight)
    return null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Helper method to build welcome screen options
  Widget _buildWelcomeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Function(BuildContext, WidgetRef, VoidCallback) handler,
  }) {
    return InkWell(
      onTap: () => handler(context, ref, () {}),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2E3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3F4B)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF64FFDA), size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the New Project button
  Widget _buildNewProjectButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // First ask for directory access
        final docFileHandler = ref.read(documentFileHandlerProvider);
        final success = await docFileHandler.requestDirectoryAccess();

        // If directory access was granted, show template selection
        if (success && context.mounted) {
          final directoryUri = ref.read(directoryUriProvider);
          if (directoryUri != null) {
            showTemplateManager(context, ref, directoryUri);
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64FFDA),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.add, size: 18),
          SizedBox(width: 6),
          Text('New Project',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openFile = ref.watch(openFileProvider);
    // Check if a folder is open to show different options
    final directoryUri = ref.watch(directoryUriProvider);
    final hasFolderOpen = directoryUri != null;

    if (openFile == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pro Coding Studio',
                  style: TextStyle(
                      color: Color(0xFF64FFDA),
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  hasFolderOpen ? 'Project Explorer' : 'Get Started',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 20),
                // Only show New Project button if no folder is open
                if (!hasFolderOpen) ...[
                  _buildNewProjectButton(context, ref),
                  const SizedBox(height: 20),
                ],
                // Use a SingleChildScrollView with Row to prevent overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // If folder is open, show New File and New Folder options
                      // If no folder is open, show New File, Open File, and Open Folder options
                      _buildWelcomeOption(
                        context: context,
                        icon: Icons.create_new_folder_outlined,
                        label: 'New File',
                        handler: handleNewFile,
                      ),
                      const SizedBox(width: 16),
                      _buildWelcomeOption(
                        context: context,
                        icon: Icons.folder_open_outlined,
                        label: 'Open File',
                        handler: handleOpenFile,
                      ),
                      const SizedBox(width: 16),
                      if (hasFolderOpen)
                        _buildWelcomeOption(
                          context: context,
                          icon: Icons.create_new_folder,
                          label: 'New Folder',
                          handler: handleNewFolder,
                        )
                      else
                        _buildWelcomeOption(
                          context: context,
                          icon: Icons.folder_outlined,
                          label: 'Open Folder',
                          handler: handleOpenFolder,
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF23262F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(styles: monokaiSublimeTheme),
                child: _controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : CodeField(
                        controller: _controller!,
                        onChanged: (value) {
                          ref.read(editorContentProvider.notifier).state =
                              value;
                          ref
                              .read(editorStateNotifierProvider.notifier)
                              .updateContent(value);
                          ref.read(hasUnsavedChangesProvider.notifier).state =
                              true;
                        },
                        textStyle: const TextStyle(
                          fontFamily: 'FiraMono',
                          fontSize: 16,
                        ),
                        cursorColor: Colors.white,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        lineNumberStyle: const LineNumberStyle(
                          textStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef EditorTextFieldStateAlias = _EditorTextFieldState;
