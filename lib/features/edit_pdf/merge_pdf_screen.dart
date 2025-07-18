import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import '../my_pdfs/my_pdfs_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pdf_provider.dart';
import '../../models/pdf_document.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class MergePDFScreen extends ConsumerStatefulWidget {
  const MergePDFScreen({Key? key}) : super(key: key);

  @override
  @override
ConsumerState<MergePDFScreen> createState() => _MergePDFScreenState();
}

class _MergePDFScreenState extends ConsumerState<MergePDFScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isMerging = false;
  String? _mergedFilePath;

  Future<void> _pickPDFs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        _mergedFilePath = null;
      });
    }
  }

  Future<void> _mergePDFs() async {
    setState(() {
      _isMerging = true;
      _mergedFilePath = null;
    });
    // Create a new PDF document.
    sf.PdfDocument mergedDocument = sf.PdfDocument();
    sf.PdfDocument? firstDoc;
    try {
      for (final file in _selectedFiles) {
        final bytes = await File(file.path!).readAsBytes();
        final sf.PdfDocument doc = sf.PdfDocument(inputBytes: bytes);
        if (firstDoc == null) {
          firstDoc = doc;
        } else {
          // Import all pages from doc into mergedDocument
          mergedDocument.pages.add().graphics.drawPdfTemplate(
            doc.pages[0].createTemplate(),
            const Offset(0, 0),
          );
          for (int i = 1; i < doc.pages.count; i++) {
            mergedDocument.pages.add().graphics.drawPdfTemplate(
              doc.pages[i].createTemplate(),
              const Offset(0, 0),
            );
          }
        }
      }
      // If only one document, use it as mergedDocument
      if (firstDoc != null && _selectedFiles.length == 1) {
        mergedDocument = firstDoc!;
      }
      final output = await getTemporaryDirectory();
      final mergedPath = "${output.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final mergedFile = File(mergedPath);
      final mergedBytes = await mergedDocument.save();
      await mergedFile.writeAsBytes(mergedBytes);
      mergedDocument.dispose();

      // Save to MyPDFs and register in provider
      final fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfDocument = await ref.read(pdfListProvider.notifier).savePdfFromBytes(
        Uint8List.fromList(mergedBytes),
        fileName,
      );

      // Try to save to external storage (Downloads)
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final externalFile = File('${downloadsDir.path}/$fileName');
          await externalFile.writeAsBytes(mergedBytes);
        }
      } catch (e) {
        // Ignore errors for external storage
      }

      setState(() {
        _isMerging = false;
        _mergedFilePath = pdfDocument?.path;
      });

      // Open the merged PDF in the in-app viewer
      if (pdfDocument != null && mounted) {
        // Open in-app viewer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PdfViewerScreen(),
          ),
        );
        // Also open in system viewer
        OpenFile.open(pdfDocument.path);
      }

    } catch (e) {
      setState(() {
        _isMerging = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to merge PDFs: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDFs'),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select two or more PDF files to merge them into a single document.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Select PDFs'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isMerging ? null : _pickPDFs,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No PDFs selected', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          Text('Tap "Select PDFs" to choose files.', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                            title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(_formatFileSize(file.size)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: _isMerging
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedFiles.removeAt(index);
                                      });
                                    },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedFiles.length < 2
                  ? ElevatedButton.icon(
                      key: const ValueKey('disabled'),
                      icon: const Icon(Icons.merge_type),
                      label: const Text('Select at least 2 PDFs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: null,
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('enabled'),
                      icon: _isMerging
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.merge_type),
                      label: Text(_isMerging ? 'Merging...' : 'Merge PDFs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isMerging ? null : _mergePDFs,
                    ),
            ),
            if (_mergedFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Merged PDF saved at: $_mergedFilePath',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
