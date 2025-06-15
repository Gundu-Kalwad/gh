import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// Shows a custom search drawer below the given anchor key.
Future<void> showSearchDrawerBelowButton({
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
            width: 320,
            child: Material(
              color: Colors.transparent,
              child: _SearchPopupDrawer(
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

class _SearchPopupDrawer extends ConsumerWidget {
  final VoidCallback onClose;
  final CodeController? controller;
  const _SearchPopupDrawer(
      {Key? key, required this.onClose, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasController = controller != null;
    // Work around @internal by casting to dynamic
    final dynamic dynController = controller;
    final searchController =
        hasController ? dynController.searchController : null;
    final searchSettingsController = searchController?.settingsController;
    final searchNavController = searchController?.navigationController;
    final TextEditingController searchFieldController = hasController
        ? searchSettingsController?.patternController ?? TextEditingController()
        : TextEditingController();

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchFieldController,
                    enabled: hasController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF181A20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: hasController
                        ? (query) {
                            searchController?.showSearch();
                            searchFieldController.text = query;
                            searchSettingsController?.patternController.text =
                                query;
                            searchController?.search(
                              controller?.text ?? '',
                              settings: searchSettingsController?.value,
                            );
                            showSnack('Searched for "$query"');
                          }
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasController)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward,
                        color: Color(0xFF64FFDA)),
                    tooltip: 'Previous',
                    onPressed: () {
                      searchNavController?.movePrevious();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward,
                        color: Color(0xFF64FFDA)),
                    tooltip: 'Next',
                    onPressed: () {
                      searchNavController?.moveNext();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.highlight_remove,
                        color: Color(0xFF64FFDA)),
                    tooltip: 'Clear',
                    onPressed: () {
                      if (searchSettingsController != null) {
                        searchSettingsController.patternController.clear();
                      }
                      searchFieldController.clear();
                    },
                  ),
                  // Show current/total result count
                  Expanded(
                    child: AnimatedBuilder(
                      animation: searchNavController,
                      builder: (context, _) {
                        final state = searchNavController?.value;
                        final current = (state?.currentMatchIndex ?? -1) + 1;
                        final total = state?.totalMatchCount ?? 0;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            total > 0 ? '$current / $total' : 'No results',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            if (!hasController)
              const Text('No editor open',
                  style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
