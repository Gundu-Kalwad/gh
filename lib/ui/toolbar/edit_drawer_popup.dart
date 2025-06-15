import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/edit_drawer/edit_drawer_logic.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// Shows a custom edit drawer below the given anchor key.
Future<void> showEditDrawerBelowButton({
  required BuildContext context,
  required GlobalKey anchorKey,
  required VoidCallback onClose,
  required CodeController? controller,
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
              child: _EditPopupDrawer(
                onClose: () {
                  entry?.remove();
                  onClose();
                },
                controller: controller,
              ),
            ),
          ),
        ],
      );
    },
  );
  Overlay.of(context).insert(entry);
}

class _EditPopupDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  final CodeController? controller;
  const _EditPopupDrawer(
      {Key? key, required this.onClose, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasController = controller != null;

    void showSnack(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg), duration: const Duration(milliseconds: 1200)),
      );
    }

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
            leading: const Icon(Icons.undo, color: Color(0xFF64FFDA)),
            title: const Text('Undo', style: TextStyle(color: Colors.white)),
            enabled: hasController,
            onTap: hasController
                ? () {
                    EditDrawerLogic.undo(controller!);
                    onClose();
                    showSnack('Undo');
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.redo, color: Color(0xFF64FFDA)),
            title: const Text('Redo', style: TextStyle(color: Colors.white)),
            enabled: hasController,
            onTap: hasController
                ? () {
                    EditDrawerLogic.redo(controller!);
                    onClose();
                    showSnack('Redo');
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: Color(0xFF64FFDA)),
            title: const Text('Copy', style: TextStyle(color: Colors.white)),
            enabled: hasController,
            onTap: hasController
                ? () {
                    EditDrawerLogic.copy(controller!);
                    onClose();
                    showSnack('Copied');
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.cut, color: Color(0xFF64FFDA)),
            title: const Text('Cut', style: TextStyle(color: Colors.white)),
            enabled: hasController,
            onTap: hasController
                ? () {
                    EditDrawerLogic.cut(controller!);
                    onClose();
                    showSnack('Cut');
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.paste, color: Color(0xFF64FFDA)),
            title: const Text('Paste', style: TextStyle(color: Colors.white)),
            enabled: hasController,
            onTap: hasController
                ? () async {
                    await EditDrawerLogic.paste(controller!);
                    onClose();
                    showSnack('Pasted');
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
