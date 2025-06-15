// This file defines the logic for managing editor tabs in a Flutter application.
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State class to track open editor tabs
class EditorTabsState {
  final List<String> openTabs;
  final String? currentTab;

  EditorTabsState({
    required this.openTabs,
    this.currentTab,
  });

  // Copy with method for immutability
  EditorTabsState copyWith({
    List<String>? openTabs,
    String? currentTab,
    bool clearCurrentTab = false,
  }) {
    return EditorTabsState(
      openTabs: openTabs ?? this.openTabs,
      currentTab: clearCurrentTab ? null : (currentTab ?? this.currentTab),
    );
  }
}

// StateNotifier to manage tabs
class EditorTabsNotifier extends StateNotifier<EditorTabsState> {
  EditorTabsNotifier() : super(EditorTabsState(openTabs: [], currentTab: null));

  // Add or focus a tab
  void openTab(String tabName) {
    // If tab already exists, just make it current
    if (state.openTabs.contains(tabName)) {
      state = state.copyWith(currentTab: tabName);
      return;
    }

    // Otherwise add it to the list and make it current
    final updatedTabs = List<String>.from(state.openTabs)..add(tabName);
    state = state.copyWith(
      openTabs: updatedTabs,
      currentTab: tabName,
    );
  }

  // Close a tab by index
  void closeTab(int index) {
    if (index < 0 || index >= state.openTabs.length) return;

    final updatedTabs = List<String>.from(state.openTabs);
    final closedTab = updatedTabs.removeAt(index);

    // If we closed the current tab, update current to null or the next available tab
    final currentTab = state.currentTab;
    final bool needsNewCurrent = closedTab == currentTab;

    state = state.copyWith(
      openTabs: updatedTabs,
      currentTab: needsNewCurrent && updatedTabs.isNotEmpty
          ? updatedTabs.last
          : currentTab,
      clearCurrentTab: needsNewCurrent && updatedTabs.isEmpty,
    );
  }

  // Close a tab by name
  void closeTabByName(String tabName) {
    final index = state.openTabs.indexOf(tabName);
    if (index >= 0) {
      closeTab(index);
    }
  }
}

// Provider for editor tabs state
final editorTabsProvider =
    StateNotifierProvider<EditorTabsNotifier, EditorTabsState>((ref) {
  return EditorTabsNotifier();
});
