import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Utility to get all PDF files from external storage (Downloads, Documents, etc.)
Future<List<FileSystemEntity>> getAllExternalPdfs() async {
  final List<FileSystemEntity> pdfFiles = [];
  // Try Downloads
  Directory? downloadsDir;
  try {
    downloadsDir = Directory('/storage/emulated/0/Download');
    if (await downloadsDir.exists()) {
      pdfFiles.addAll(downloadsDir
          .listSync(recursive: true)
          .where((file) => file.path.toLowerCase().endsWith('.pdf')));
    }
  } catch (_) {}
  // Try Documents
  try {
    final docsDir = Directory('/storage/emulated/0/Documents');
    if (await docsDir.exists()) {
      pdfFiles.addAll(docsDir
          .listSync(recursive: true)
          .where((file) => file.path.toLowerCase().endsWith('.pdf')));
    }
  } catch (_) {}
  // Optionally add more directories
  return pdfFiles;
}
