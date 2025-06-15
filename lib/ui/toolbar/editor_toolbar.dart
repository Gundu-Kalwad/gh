import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pro_coding_studio/logic/github_operations/artifact/run_button_logic.dart';
import 'package:pro_coding_studio/ui/toolbar/explorer_ui.dart';
import 'package:pro_coding_studio/ui/toolbar/more_button/more_panel.dart';
import 'package:pro_coding_studio/ui/toolbar/menu_drawer_popup.dart';
import 'package:pro_coding_studio/ui/github/github_drawer.dart';
import 'package:pro_coding_studio/ui/ai/ai_drawer.dart';
import 'package:pro_coding_studio/ui/toolbar/edit_drawer_popup.dart';
import 'package:pro_coding_studio/ui/toolbar/search_drawer_popup.dart';

class _ToolbarButtonData {
  final IconData? icon;
  final String label;
  final String? svgAsset;
  final VoidCallback? onPressed;
  const _ToolbarButtonData({
    this.icon,
    required this.label,
    this.svgAsset,
    this.onPressed,
  });
}

class EditorToolbar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onExplorerPressed;
  const EditorToolbar({Key? key, this.onExplorerPressed}) : super(key: key);

  static final GlobalKey editorTextFieldKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Buttons for scrollable toolbar (Files button now handled by ExplorerButton)
    final GlobalKey menuButtonKey = GlobalKey();
    final GlobalKey editButtonKey = GlobalKey();
    final List<_ToolbarButtonData> scrollButtons = [
      _ToolbarButtonData(icon: Icons.menu, label: 'Menu'),
      _ToolbarButtonData(icon: Icons.edit, label: 'Edit'),
      _ToolbarButtonData(
        icon: Icons.play_arrow,
        label: 'Run',
        onPressed: () async {
          // Call logic handler for run button
          await RunButtonLogic.handleRunButton(context, ref);
        },
      ),
      _ToolbarButtonData(icon: Icons.search, label: 'Search'),
      _ToolbarButtonData(
          icon: Icons.build,
          label: 'Build',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming Soon')),
            );
          }),
      _ToolbarButtonData(
        svgAsset: 'assets/icons/github.svg',
        label: 'Github',
        onPressed: () {
          Scaffold.of(context).openEndDrawer();
        },
      ),
      _ToolbarButtonData(
        svgAsset: 'assets/icons/ai.svg',
        label: 'mbrowser',
        onPressed: () {
          // Open the AI drawer from the left side
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AIDrawer(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); // Start from right
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        },
      ),
      _ToolbarButtonData(icon: Icons.more_horiz, label: 'More'),
    ];

    return Material(
      color: const Color(0xFF22242A),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Static Files button
              // Use the ExplorerButton UI for Files/Explorer
              ExplorerButton(onPressed: onExplorerPressed),
              // Scrollable toolbar for the rest
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: preferredSize.height,
                    ),
                    child: SizedBox(
                      height: preferredSize.height,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: scrollButtons.asMap().entries.map((entry) {
                          final button = entry.value;
                          // Assign keys for Menu and Edit buttons
                          Key? key;
                          if (button.label == 'Menu') key = menuButtonKey;
                          if (button.label == 'Edit') key = editButtonKey;
                          if (button.label == 'Search') key = GlobalKey();
                          return Padding(
                            padding: EdgeInsets.zero,
                            child: TextButton(
                              key: key,
                              onPressed: button.onPressed ??
                                  (button.label == 'Menu'
                                      ? () {
                                          ref
                                              .read(menuDrawerVisibleProvider
                                                  .notifier)
                                              .state = true;
                                          showMenuDrawerBelowButton(
                                            context: context,
                                            anchorKey: menuButtonKey,
                                            onClose: () {
                                              ref
                                                  .read(
                                                      menuDrawerVisibleProvider
                                                          .notifier)
                                                  .state = false;
                                            },
                                          );
                                        }
                                      : button.label == 'Edit'
                                          ? () {
                                              final state = EditorToolbar
                                                  .editorTextFieldKey
                                                  .currentState as dynamic;
                                              final controller =
                                                  state?.exposedController;
                                              showEditDrawerBelowButton(
                                                context: context,
                                                anchorKey: editButtonKey,
                                                onClose: () {},
                                                controller: controller,
                                              );
                                            }
                                          : button.label == 'Search'
                                              ? () {
                                                  final state = EditorToolbar
                                                      .editorTextFieldKey
                                                      .currentState as dynamic;
                                                  final controller =
                                                      state?.exposedController;
                                                  showSearchDrawerBelowButton(
                                                    context: context,
                                                    anchorKey: key as GlobalKey,
                                                    onClose: () {},
                                                    controller: controller,
                                                  );
                                                }
                                              : button.label == 'More'
                                                  ? () {
                                                      showGeneralDialog(
                                                        context: context,
                                                        barrierLabel: 'More',
                                                        barrierDismissible:
                                                            true,
                                                        barrierColor:
                                                            Colors.black54,
                                                        transitionDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    350),
                                                        pageBuilder: (context,
                                                                anim1, anim2) =>
                                                            const SizedBox
                                                                .shrink(),
                                                        transitionBuilder:
                                                            (context, anim1,
                                                                anim2, child) {
                                                          final offset = Tween<
                                                              Offset>(
                                                            begin: const Offset(
                                                                1, 0),
                                                            end: Offset.zero,
                                                          ).animate(
                                                              CurvedAnimation(
                                                            parent: anim1,
                                                            curve: Curves
                                                                .easeOutCubic,
                                                          ));
                                                          return SlideTransition(
                                                            position: offset,
                                                            child: MorePanel(),
                                                          );
                                                        },
                                                      );
                                                    }
                                                  : null),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: SizedBox(
                                height: 40,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    button.svgAsset != null
                                        ? SvgPicture.asset(
                                            button.svgAsset!,
                                            width: 24,
                                            height: 24,
                                            color: Colors.white,
                                          )
                                        : Icon(button.icon,
                                            color: Colors.white, size: 24),
                                    const SizedBox(height: 2),
                                    Text(
                                      button.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
