import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TextToPdfService {
  // Convert plain text to PDF
  static Future<Uint8List> createPdfFromText(
    String text, {
    String? title,
    double fontSize = 12,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (title != null && title.isNotEmpty)
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: fontSize + 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Paragraph(
              text: text,
              style: pw.TextStyle(fontSize: fontSize, lineSpacing: 1.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Create PDF with custom formatting
  static Future<Uint8List> createFormattedPdf({
    required String content,
    String? title,
    String? author,
    double fontSize = 12,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    bool includePageNumbers = true,
    bool includeTimestamp = true,
  }) async {
    final pdf = pw.Document(
      title: title,
      author: author,
      creator: 'Hello PDF App',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          if (title != null && title.isNotEmpty) {
            return pw.Container(
              alignment: pw.Alignment.centerLeft,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: fontSize + 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (includePageNumbers)
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: fontSize - 2),
                  ),
                if (includeTimestamp)
                  pw.Text(
                    'Generated on ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(fontSize: fontSize - 3),
                  ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.Paragraph(
              text: content,
              style: pw.TextStyle(fontSize: fontSize, lineSpacing: 1.5),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Create multi-column PDF
  static Future<Uint8List> createMultiColumnPdf(
    String text, {
    String? title,
    int columns = 2,
    double fontSize = 10,
  }) async {
    final pdf = pw.Document();

    // Split text into chunks for columns
    final words = text.split(' ');
    final wordsPerColumn = (words.length / columns).ceil();
    final columnTexts = <String>[];

    for (int i = 0; i < columns; i++) {
      final startIndex = i * wordsPerColumn;
      final endIndex = ((i + 1) * wordsPerColumn).clamp(0, words.length);
      if (startIndex < words.length) {
        columnTexts.add(words.sublist(startIndex, endIndex).join(' '));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (title != null && title.isNotEmpty)
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: fontSize + 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  columnTexts.map((columnText) {
                    return pw.Expanded(
                      child: pw.Container(
                        margin: const pw.EdgeInsets.only(right: 16),
                        child: pw.Text(
                          columnText,
                          style: pw.TextStyle(
                            fontSize: fontSize,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Create PDF with table format
  static Future<Uint8List> createTablePdf(
    List<List<String>> tableData, {
    String? title,
    List<String>? headers,
    double fontSize = 10,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (title != null && title.isNotEmpty)
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: fontSize + 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.Table.fromTextArray(
              headers: headers,
              data: tableData,
              headerStyle: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: pw.TextStyle(fontSize: fontSize),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignments: Map.fromIterable(
                List.generate(
                  headers?.length ??
                      (tableData.isNotEmpty ? tableData[0].length : 0),
                  (index) => index,
                ),
                value: (item) => pw.Alignment.centerLeft,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
