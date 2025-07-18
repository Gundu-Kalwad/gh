import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfTestUtils {
  /// Create sample PDF files for testing merge functionality
  static Future<List<File>> createSamplePdfs() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<File> sampleFiles = [];

    // Create first sample PDF
    final pdf1 = pw.Document();
    pdf1.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Sample PDF 1',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('This is the first sample PDF document.'),
              pw.Text('It contains some sample content for testing.'),
            ],
          ),
        ),
      ),
    );

    final file1 = File('${directory.path}/sample_pdf_1.pdf');
    await file1.writeAsBytes(await pdf1.save());
    sampleFiles.add(file1);

    // Create second sample PDF
    final pdf2 = pw.Document();
    pdf2.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Sample PDF 2',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('This is the second sample PDF document.'),
              pw.Text('It has different content from the first one.'),
              pw.SizedBox(height: 20),
              pw.Container(
                width: 100,
                height: 100,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'Box',
                    style: pw.TextStyle(color: PdfColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final file2 = File('${directory.path}/sample_pdf_2.pdf');
    await file2.writeAsBytes(await pdf2.save());
    sampleFiles.add(file2);

    // Create third sample PDF with multiple pages
    final pdf3 = pw.Document();
    
    // Page 1
    pdf3.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Sample PDF 3 - Page 1'),
            ),
            pw.SizedBox(height: 20),
            pw.Text('This is a multi-page PDF document.'),
            pw.Text('Page 1 content goes here.'),
            pw.SizedBox(height: 20),
            pw.Bullet(text: 'Bullet point 1'),
            pw.Bullet(text: 'Bullet point 2'),
            pw.Bullet(text: 'Bullet point 3'),
          ],
        ),
      ),
    );

    // Page 2
    pdf3.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Sample PDF 3 - Page 2'),
            ),
            pw.SizedBox(height: 20),
            pw.Text('This is the second page of the multi-page PDF.'),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Column 1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Column 2', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Row 1, Col 1'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Row 1, Col 2'),
                  ),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Row 2, Col 1'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Row 2, Col 2'),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );

    final file3 = File('${directory.path}/sample_pdf_3.pdf');
    await file3.writeAsBytes(await pdf3.save());
    sampleFiles.add(file3);

    return sampleFiles;
  }

  /// Delete sample PDF files
  static Future<void> deleteSamplePdfs() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = [
      'sample_pdf_1.pdf',
      'sample_pdf_2.pdf',
      'sample_pdf_3.pdf',
    ];

    for (final fileName in files) {
      final file = File('${directory.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Check if sample PDFs exist
  static Future<bool> samplePdfsExist() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = [
      'sample_pdf_1.pdf',
      'sample_pdf_2.pdf',
      'sample_pdf_3.pdf',
    ];

    for (final fileName in files) {
      final file = File('${directory.path}/$fileName');
      if (!(await file.exists())) {
        return false;
      }
    }
    return true;
  }
}
