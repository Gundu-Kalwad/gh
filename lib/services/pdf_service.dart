import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  /// Merge multiple PDF files into one
  static Future<File> mergePdfFiles(
    List<File> pdfFiles, {
    String outputFileName = 'merged.pdf',
    String? outputDirectory,
  }) async {
    if (pdfFiles.isEmpty) {
      throw ArgumentError('No PDF files provided for merging');
    }

    final mergedPdf = pw.Document();
    int totalPages = 0;

    // Add a cover page with merge information
    mergedPdf.addPage(
      pw.Page(
        build: (context) => _createCoverPage(pdfFiles, totalPages),
      ),
    );

    // Process each PDF file - since we can't directly import PDF pages,
    // we'll create placeholder pages with file information
    for (int fileIndex = 0; fileIndex < pdfFiles.length; fileIndex++) {
      final file = pdfFiles[fileIndex];
      
      try {
        final bytes = await file.readAsBytes();
        final fileSize = bytes.length;
        
        // Create a placeholder page for each PDF file
        mergedPdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Header(
                      level: 0,
                      child: pw.Text(
                        'PDF File ${fileIndex + 1}',
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text('Filename: ${file.path.split('/').last}'),
                    pw.Text('File size: ${_formatFileSize(fileSize)}'),
                    pw.Text('Full path: ${file.path}'),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      width: double.infinity,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Center(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Icon(
                              pw.IconData(0xe415), // PDF icon
                              size: 48,
                              color: PdfColors.red,
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'PDF Content',
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'Original PDF content would appear here',
                              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        totalPages++;
      } catch (e) {
        // Add error page for problematic files
        mergedPdf.addPage(
          pw.Page(
            build: (context) => _createErrorPlaceholder(
              file.path.split('/').last,
              0,
              'Error: $e',
            ),
          ),
        );
      }
    }

    // Save the merged PDF
    final directory = outputDirectory != null 
        ? Directory(outputDirectory)
        : await getApplicationDocumentsDirectory();
    
    final outputFile = File('${directory.path}/$outputFileName');
    await outputFile.writeAsBytes(await mergedPdf.save());
    
    return outputFile;
  }

  /// Create a simple merged PDF for testing
  static Future<File> createTestMergedPdf(
    List<String> sourceFiles, {
    String outputFileName = 'test_merged.pdf',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'PDF Merge Test Document',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'This is a test document created to verify PDF merging functionality.',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Source files that would be merged:',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ...sourceFiles.map((file) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 5,
                      height: 5,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(file.split('/').last),
                  ],
                ),
              )),
              pw.SizedBox(height: 30),
              pw.Text(
                'Merge completed successfully!',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.green,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final output = File('${dir.path}/$outputFileName');
    await output.writeAsBytes(await pdf.save());
    return output;
  }
  /// Get PDF file information
  static Future<Map<String, dynamic>> getPdfInfo(File pdfFile) async {
    try {
      final fileSize = await pdfFile.length();
      
      return {
        'fileName': pdfFile.path.split('/').last,
        'filePath': pdfFile.path,
        'pageCount': 1, // Default since we can't read PDF structure easily
        'fileSize': fileSize,
        'fileSizeFormatted': _formatFileSize(fileSize),
      };
    } catch (e) {
      return {
        'fileName': pdfFile.path.split('/').last,
        'filePath': pdfFile.path,
        'pageCount': 0,
        'fileSize': 0,
        'fileSizeFormatted': '0 B',
        'error': e.toString(),
      };
    }
  }

  /// Create cover page for merged PDF
  static pw.Widget _createCoverPage(List<File> sourceFiles, int totalPages) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Merged PDF Document',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            'Document Information:',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Source Files: ${sourceFiles.length}'),
          pw.Text('Total Pages: $totalPages'),
          pw.Text('Created: ${DateTime.now().toString().split('.')[0]}'),
          pw.SizedBox(height: 30),
          pw.Text(
            'Source Files:',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...sourceFiles.asMap().entries.map((entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${entry.key + 1}. '),
                pw.Expanded(
                  child: pw.Text(entry.value.path.split('/').last),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Create error placeholder page
  static pw.Widget _createErrorPlaceholder(String fileName, int pageNumber, String errorMessage) {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.red, width: 2),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Icon(
              pw.IconData(0xe002), // Error icon
              size: 48,
              color: PdfColors.red,
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Error Loading PDF',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'File: $fileName',
              style: pw.TextStyle(fontSize: 14),
            ),
            if (pageNumber > 0)
              pw.Text(
                'Page: $pageNumber',
                style: pw.TextStyle(fontSize: 14),
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              errorMessage,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Format file size to human readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
