import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_service.dart';

// State class for PDF merge operations
class PdfMergeState {
  final List<File> selectedFiles;
  final bool isLoading;
  final String? error;
  final File? mergedFile;

  const PdfMergeState({
    this.selectedFiles = const [],
    this.isLoading = false,
    this.error,
    this.mergedFile,
  });

  PdfMergeState copyWith({
    List<File>? selectedFiles,
    bool? isLoading,
    String? error,
    File? mergedFile,
  }) {
    return PdfMergeState(
      selectedFiles: selectedFiles ?? this.selectedFiles,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      mergedFile: mergedFile ?? this.mergedFile,
    );
  }
}

// Provider for PDF merge functionality
class PdfMergeNotifier extends StateNotifier<PdfMergeState> {
  PdfMergeNotifier() : super(const PdfMergeState());

  void addFiles(List<File> files) {
    state = state.copyWith(
      selectedFiles: [...state.selectedFiles, ...files],
      error: null,
    );
  }

  void removeFile(int index) {
    final newFiles = [...state.selectedFiles];
    newFiles.removeAt(index);
    state = state.copyWith(selectedFiles: newFiles);
  }

  void clearFiles() {
    state = state.copyWith(selectedFiles: []);
  }
  Future<void> mergePdfs({String outputFileName = 'merged.pdf'}) async {
    if (state.selectedFiles.isEmpty) {
      state = state.copyWith(error: 'No files selected for merging');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final mergedFile = await PdfService.mergePdfFiles(
        state.selectedFiles,
        outputFileName: outputFileName,
      );
      
      state = state.copyWith(
        isLoading: false,
        mergedFile: mergedFile,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to merge PDFs: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearMergedFile() {
    state = state.copyWith(mergedFile: null);
  }
}

// Provider instance
final pdfMergeProvider = StateNotifierProvider<PdfMergeNotifier, PdfMergeState>(
  (ref) => PdfMergeNotifier(),
);
