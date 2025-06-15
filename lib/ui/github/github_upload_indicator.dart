import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/github_operations/github_repo_operations.dart';

/// A simple, non-intrusive loading indicator for GitHub operations
/// Displays in the bottom left corner of the screen
class GitHubUploadIndicator extends ConsumerWidget {
  const GitHubUploadIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(uploadProgressProvider);
    final message = ref.watch(repoOperationMessageProvider);

    // Only show when an operation is in progress
    if (progress == null) return const SizedBox();

    return Positioned(
      left: 16,
      bottom: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                const Color(0xFF23262F), // Dark background to match app theme
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: const Color(0xFF2F3341), width: 1), // Subtle border
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4D8CFE), // Blue color to match app theme
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAEB4C6), // Light gray text for dark theme
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
