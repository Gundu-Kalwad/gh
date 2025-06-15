import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter/services.dart';

/// Provides edit actions for the Edit drawer (Undo, Redo, Copy, Cut, Paste)
class EditDrawerLogic {
  /// Undo the last action in the code editor
  static void undo(CodeController controller) {
    controller.historyController.undo();
  }

  /// Redo the last undone action in the code editor
  static void redo(CodeController controller) {
    controller.historyController.redo();
  }

  /// Copy the selected text to the clipboard
  static void copy(CodeController controller) {
    final selection = controller.selection;
    if (!selection.isCollapsed) {
      final selectedText =
          controller.text.substring(selection.start, selection.end);
      Clipboard.setData(ClipboardData(text: selectedText));
    }
  }

  /// Cut the selected text to the clipboard
  static void cut(CodeController controller) {
    final selection = controller.selection;
    if (!selection.isCollapsed) {
      final selectedText =
          controller.text.substring(selection.start, selection.end);
      Clipboard.setData(ClipboardData(text: selectedText));
      final newText =
          controller.text.replaceRange(selection.start, selection.end, '');
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start);
    }
  }

  /// Paste text from the clipboard at the current cursor position
  static Future<void> paste(CodeController controller) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final selection = controller.selection;
      final newText = controller.text.replaceRange(
        selection.start,
        selection.end,
        data!.text!,
      );
      final cursorPos = selection.start + data.text!.length;
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: cursorPos);
    }
  }
}
