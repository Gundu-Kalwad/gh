import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/editor_logic.dart';
import 'package:pro_coding_studio/logic/tabs/editor_tabs_logic.dart';

/// A tab system for code editor that integrates with Riverpod state management
class EditorTabs extends ConsumerWidget {
  const EditorTabs({
    Key? key,
    this.onTabSelected,
    this.onTabClose,
  }) : super(key: key);

  final void Function(int)? onTabSelected;
  final void Function(int)? onTabClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get tab state from the provider
    final tabsState = ref.watch(editorTabsProvider);
    final tabs = tabsState.openTabs;
    final currentTab = tabsState.currentTab;

    // Get the selectedIndex based on the current tab
    final selectedIndex = currentTab != null ? tabs.indexOf(currentTab) : -1;

    // Check unsaved changes to show indicator
    final hasUnsavedChanges = ref.watch(hasUnsavedChangesProvider);

    // If no tabs are open, show an empty container
    if (tabs.isEmpty) {
      return Container(
        height: 40,
        color: const Color(0xFF282B33),
        child: const Center(
          child: Text(
            'No files open - use the explorer to open files',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      color: const Color(0xFF282B33),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final bool isSelected = index == selectedIndex;
          final bool isUnsaved = isSelected && hasUnsavedChanges;

          return GestureDetector(
            onTap: () {
              // Call callback if provided
              onTabSelected?.call(index);

              // Update the current tab
              ref.read(editorTabsProvider.notifier).openTab(tabs[index]);

              // Also update the openFile provider to maintain compatibility
              ref.read(openFileProvider.notifier).state = tabs[index];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF181A20)
                    : const Color(0xFF23262F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF64FFDA)
                      : const Color(0xFF282B33),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF64FFDA).withOpacity(0.16),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnsaved)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF64FFDA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    tabs[index],
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFF64FFDA) : Colors.white60,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // Call the close callback if provided
                      onTabClose?.call(index);

                      // Close the tab
                      ref.read(editorTabsProvider.notifier).closeTab(index);

                      // If closing the current tab, reset other state
                      if (isSelected) {
                        // Update openFile to match the new current tab (or null)
                        final newState = ref.read(editorTabsProvider);
                        ref.read(openFileProvider.notifier).state =
                            newState.currentTab;

                        // Reset unsaved changes for the closed tab
                        ref.read(hasUnsavedChangesProvider.notifier).state =
                            false;
                      }
                    },
                    child: const Icon(Icons.close,
                        size: 16, color: Colors.white38),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
