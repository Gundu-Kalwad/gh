import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pdf_provider.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import 'package:open_file/open_file.dart';

class SplitPDFScreen extends ConsumerStatefulWidget {
  const SplitPDFScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplitPDFScreen> createState() => _SplitPDFScreenState();
}

class _SplitPDFScreenState extends ConsumerState<SplitPDFScreen> {
  PlatformFile? _selectedFile;
  int? _pageCount;
  final TextEditingController _rangeController = TextEditingController();
  bool _isSplitting = false;
  String? _outputPath;

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      try {
        final bytes = await File(file.path!).readAsBytes();
        final doc = sf.PdfDocument(inputBytes: bytes);
        setState(() {
          _selectedFile = file;
          _pageCount = doc.pages.count;
          _outputPath = null;
        });
        doc.dispose();
      } catch (e) {
        setState(() {
          _selectedFile = null;
          _pageCount = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
      }
    }
  }

  Future<void> _splitPDF() async {
    if (_selectedFile == null || _pageCount == null) return;
    setState(() => _isSplitting = true);
    try {
      final bytes = await File(_selectedFile!.path!).readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      final ranges = _parsePageRanges(_rangeController.text, _pageCount!);
      if (ranges.isEmpty) {
        throw 'Invalid page range.';
      }
      final splitDoc = sf.PdfDocument();
      for (final pageNum in ranges) {
        splitDoc.pages.add().graphics.drawPdfTemplate(
          doc.pages[pageNum - 1].createTemplate(),
          const Offset(0, 0),
        );
      }
      final output = await getTemporaryDirectory();
      final fileName = 'split_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final splitPath = "${output.path}/$fileName";
      final splitFile = File(splitPath);
      final splitBytes = await splitDoc.save();
      await splitFile.writeAsBytes(splitBytes);
      splitDoc.dispose();
      doc.dispose();
      // Register in provider
      final pdfDocument = await ref.read(pdfListProvider.notifier).savePdfFromBytes(
        Uint8List.fromList(splitBytes),
        fileName,
      );
      setState(() {
        _isSplitting = false;
        _outputPath = pdfDocument?.path;
      });
      // Open in-app viewer
      if (pdfDocument != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
        );
        OpenFile.open(pdfDocument.path);
      }
    } catch (e) {
      setState(() => _isSplitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to split PDF: $e')),
      );
    }
  }

  List<int> _parsePageRanges(String input, int maxPage) {
    final Set<int> pages = {};
    final parts = input.split(',');
    for (final part in parts) {
      final range = part.trim();
      if (range.isEmpty) continue;
      if (range.contains('-')) {
        final bounds = range.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0]);
          final end = int.tryParse(bounds[1]);
          if (start != null && end != null && start <= end && start > 0 && end <= maxPage) {
            pages.addAll(List.generate(end - start + 1, (i) => start + i));
          }
        }
      } else {
        final page = int.tryParse(range);
        if (page != null && page > 0 && page <= maxPage) {
          pages.add(page);
        }
      }
    }
    return pages.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Select PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orangeAccent,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSplitting ? null : _pickPDF,
            ),
            const SizedBox(height: 24),
            if (_selectedFile != null)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                  title: Text(_selectedFile!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(_pageCount != null ? '$_pageCount pages' : ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isSplitting
                        ? null
                        : () {
                            setState(() {
                              _selectedFile = null;
                              _pageCount = null;
                              _rangeController.clear();
                            });
                          },
                  ),
                ),
              ),
            if (_selectedFile != null && _pageCount != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: _rangeController,
                  enabled: !_isSplitting,
                  decoration: InputDecoration(
                    labelText: 'Pages to extract (e.g. 1-3,5,7)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.text,
                ),
              ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_selectedFile == null || _isSplitting)
                  ? ElevatedButton.icon(
                      key: const ValueKey('disabled'),
                      icon: const Icon(Icons.call_split),
                      label: Text(_isSplitting ? 'Splitting...' : 'Split PDF'),
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
                      icon: _isSplitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.call_split),
                      label: const Text('Split PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _splitPDF,
                    ),
            ),
            if (_outputPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Split PDF saved at: $_outputPath',
                        style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.w600),
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
}
