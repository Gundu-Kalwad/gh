import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';

/// Shows a custom menu drawer below the given anchor key.
Future<void> showMenuDrawerBelowButton({
  required BuildContext context,
  required GlobalKey anchorKey,
  required VoidCallback onClose,
}) async {
  final RenderBox renderBox =
      anchorKey.currentContext!.findRenderObject() as RenderBox;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Size size = renderBox.size;

  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Tap barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                entry?.remove();
                onClose();
              },
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),
          // The actual popup drawer
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height,
            width: 220,
            child: Material(
              color: Colors.transparent,
              child: _PopupMenuDrawer(
                onClose: () {
                  entry?.remove();
                  onClose();
                },
              ),
            ),
          ),
        ],
      );
    },
  );
  Overlay.of(context).insert(entry);
}

// Optional: Provider for menu drawer visibility
final menuDrawerVisibleProvider = StateProvider<bool>((ref) => false);

// Helper functions for menu actions with SnackBar feedback
void showActionSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void handleNewFile(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  // Close the menu drawer first
  onClose();

  // Then show the dialog and perform the operation
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.createNewFile(context);

  if (success) {
    showActionSnackBar(context, 'New file created');
  }
}

void handleNewFolder(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  // Close the menu drawer first
  onClose();

  // Then show the dialog and perform the operation
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.createNewFolder(context);

  if (success) {
    showActionSnackBar(context, 'New folder created');
  }
}

void handleOpenFile(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.openFile(context);

  onClose();

  if (success) {
    showActionSnackBar(context, 'File opened');
  }
}

void handleOpenFolder(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.openFolder(context);

  onClose();

  if (success) {
    showActionSnackBar(context, 'Folder opened');
  }
}

void handleSave(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.saveFile(context);

  onClose();

  if (success) {
    showActionSnackBar(context, 'File saved');
  }
}

Future<void> handleSaveAs(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.saveFileAs(context);

  if (context.mounted) {
    onClose();
    if (success) {
      showActionSnackBar(context, 'File saved as new');
    }
  }
}

void handleSaveAll(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.saveAllFiles(context);

  onClose();

  if (success) {
    showActionSnackBar(context, 'All files saved');
  } else {
    showActionSnackBar(context, 'Some files could not be saved');
  }
}

void handleCloseFile(
    BuildContext context, WidgetRef ref, VoidCallback onClose) {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  editorOps.closeFile();

  onClose();
  showActionSnackBar(context, 'File closed');
}

void handleCloseFolder(
    BuildContext context, WidgetRef ref, VoidCallback onClose) {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  editorOps.closeFolder();

  onClose();
  showActionSnackBar(context, 'Folder closed');
}

void handleDeleteFile(
    BuildContext context, WidgetRef ref, VoidCallback onClose) async {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  final success = await editorOps.deleteFile(context);

  onClose();

  if (success) {
    showActionSnackBar(context, 'File deleted');
  }
}

void handleExit(BuildContext context, WidgetRef ref, VoidCallback onClose) {
  final editorOps = ref.read(editorDocumentOperationsProvider(ref));
  editorOps.exitApplication();

  onClose();
  showActionSnackBar(context, 'Exited');
}

class _PopupMenuDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  const _PopupMenuDrawer({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF23262F),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.note_add, color: Color(0xFF64FFDA)),
            title:
                const Text('New File', style: TextStyle(color: Colors.white)),
            onTap: () => handleNewFile(context, ref, onClose),
          ),
          ListTile(
            leading:
                const Icon(Icons.create_new_folder, color: Color(0xFF64FFDA)),
            title:
                const Text('New Folder', style: TextStyle(color: Colors.white)),
            onTap: () => handleNewFolder(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Color(0xFF64FFDA)),
            title:
                const Text('Open File', style: TextStyle(color: Colors.white)),
            onTap: () => handleOpenFile(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined,
                color: Color(0xFF64FFDA)),
            title: const Text('Open Folder',
                style: TextStyle(color: Colors.white)),
            onTap: () => handleOpenFolder(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.save, color: Color(0xFF64FFDA)),
            title: const Text('Save', style: TextStyle(color: Colors.white)),
            onTap: () => handleSave(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.save_as, color: Color(0xFF64FFDA)),
            title: const Text('Save As', style: TextStyle(color: Colors.white)),
            onTap: () => handleSaveAs(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt, color: Color(0xFF64FFDA)),
            title:
                const Text('Save All', style: TextStyle(color: Colors.white)),
            onTap: () => handleSaveAll(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Color(0xFF64FFDA)),
            title:
                const Text('Close File', style: TextStyle(color: Colors.white)),
            onTap: () => handleCloseFile(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.folder_delete, color: Color(0xFF64FFDA)),
            title: const Text('Close Folder',
                style: TextStyle(color: Colors.white)),
            onTap: () => handleCloseFolder(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Color(0xFF64FFDA)),
            title: const Text('Delete File',
                style: TextStyle(color: Colors.white)),
            onTap: () => handleDeleteFile(context, ref, onClose),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Color(0xFF64FFDA)),
            title: const Text('Exit', style: TextStyle(color: Colors.white)),
            onTap: () => handleExit(context, ref, onClose),
          ),
        ],
      ),
    );
  }
}
