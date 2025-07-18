import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pdf_document.dart';
import '../services/file_service.dart';

// Provider for PDF documents list
final pdfListProvider =
    StateNotifierProvider<PdfListNotifier, List<PdfDocument>>((ref) {
      return PdfListNotifier();
    });

// Provider for loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Provider for selected PDF document
final selectedPdfProvider = StateProvider<PdfDocument?>((ref) => null);

class PdfListNotifier extends StateNotifier<List<PdfDocument>> {
  PdfListNotifier() : super([]) {
    loadPdfs();
  }

  // Load PDFs from storage
  Future<void> loadPdfs() async {
    try {
      final pdfs = await FileService.loadPdfMetadata();
      state = pdfs;
    } catch (e) {
      print('Error loading PDFs: $e');
      state = [];
    }
  }

  // Add new PDF document
  Future<void> addPdf(PdfDocument document) async {
    try {
      state = [...state, document];
      await _savePdfs();
    } catch (e) {
      print('Error adding PDF: $e');
    }
  }

  // Remove PDF document
  Future<void> removePdf(String documentId) async {
    try {
      final document = state.firstWhere((doc) => doc.id == documentId);
      await FileService.deletePdf(document);
      state = state.where((doc) => doc.id != documentId).toList();
      await _savePdfs();
    } catch (e) {
      print('Error removing PDF: $e');
    }
  }

  // Update PDF document
  Future<void> updatePdf(PdfDocument updatedDocument) async {
    try {
      state =
          state.map((doc) {
            return doc.id == updatedDocument.id ? updatedDocument : doc;
          }).toList();
      await _savePdfs();
    } catch (e) {
      print('Error updating PDF: $e');
    }
  }

  // Save PDF from bytes
  Future<PdfDocument?> savePdfFromBytes(
    Uint8List bytes,
    String fileName, {
    bool isPasswordProtected = false,
  }) async {
    try {
      final tempFile = File(
        '${(await FileService.getAppDocumentsDirectory()).path}/temp_$fileName',
      );
      await tempFile.writeAsBytes(bytes);

      final finalPath = await FileService.savePdfToAppDirectory(
        tempFile.path,
        fileName,
      );
      await tempFile.delete();

      final pageCount = 1; // Default value after removing PdfEditingService
      final fileSizeInMB = await FileService.getFileSizeInMB(finalPath);

      final document = PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: finalPath,
        createdAt: DateTime.now(),
        pageCount: pageCount,
        isPasswordProtected: isPasswordProtected,
        fileSizeInMB: fileSizeInMB,
      );

      await addPdf(document);
      return document;
    } catch (e) {
      print('Error saving PDF from bytes: $e');
      return null;
    }
  }

  // Move PDF to download folder
  Future<bool> movePdfToDownload(String documentId) async {
    try {
      final document = state.firstWhere((doc) => doc.id == documentId);
      return await FileService.movePdfToDownload(document.path, document.name);
    } catch (e) {
      print('Error moving PDF to download: $e');
      return false;
    }
  }

  // Private method to save PDFs metadata
  Future<void> _savePdfs() async {
    await FileService.savePdfMetadata(state);
  }

  // Clear all PDFs
  Future<void> clearAll() async {
    for (final document in state) {
      await FileService.deletePdf(document);
    }
    state = [];
    await _savePdfs();
  }
}
