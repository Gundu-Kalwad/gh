import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pdf_document.dart';

class FileService {
  static const String _pdfFolderName = 'hello_pdf_documents';
  static const String _metadataFileName = 'documents_metadata.json';

  // Get app documents directory
  static Future<Directory> getAppDocumentsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDocDir.path}/$_pdfFolderName');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  // Get download directory
  static Future<Directory?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return Directory('/storage/emulated/0/Download');
      }
    }
    return null;
  }

  // Save PDF to app directory
  static Future<String> savePdfToAppDirectory(
    String sourcePath,
    String fileName,
  ) async {
    final appDir = await getAppDocumentsDirectory();
    final targetPath = '${appDir.path}/$fileName';
    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  // Move PDF to download folder
  static Future<bool> movePdfToDownload(
    String sourcePath,
    String fileName,
  ) async {
    try {
      final downloadDir = await getDownloadDirectory();
      if (downloadDir != null) {
        final targetPath = '${downloadDir.path}/$fileName';
        final sourceFile = File(sourcePath);
        await sourceFile.copy(targetPath);
        return true;
      }
    } catch (e) {
      print('Error moving to download: $e');
    }
    return false;
  }

  // Save PDF metadata
  static Future<void> savePdfMetadata(List<PdfDocument> documents) async {
    final appDir = await getAppDocumentsDirectory();
    final metadataFile = File('${appDir.path}/$_metadataFileName');
    final jsonData = documents.map((doc) => doc.toJson()).toList();
    await metadataFile.writeAsString(json.encode(jsonData));
  }

  // Load PDF metadata
  static Future<List<PdfDocument>> loadPdfMetadata() async {
    try {
      final appDir = await getAppDocumentsDirectory();
      final metadataFile = File('${appDir.path}/$_metadataFileName');
      if (await metadataFile.exists()) {
        final jsonString = await metadataFile.readAsString();
        final List<dynamic> jsonData = json.decode(jsonString);
        return jsonData.map((item) => PdfDocument.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading metadata: $e');
    }
    return [];
  }

  // Delete PDF file and metadata
  static Future<bool> deletePdf(PdfDocument document) async {
    try {
      final file = File(document.path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    return false;
  }

  // Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    }
    return 0.0;
  }
}
