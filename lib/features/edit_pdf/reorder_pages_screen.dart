import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../features/my_pdfs/my_pdfs_storage.dart';
import '../../services/file_service.dart';
import 'pdf_page_thumbnail.dart';

class ReorderPagesScreen extends StatefulWidget {
  const ReorderPagesScreen({Key? key}) : super(key: key);

  @override
  State<ReorderPagesScreen> createState() => _ReorderPagesScreenState();
}

class _ReorderPagesScreenState extends State<ReorderPagesScreen> {
  File? _pdfFile;
  Uint8List? _pdfBytes;
  List<int> _pageOrder = [];
  int _pageCount = 0;
  bool _isProcessing = false;
  String? _errorMsg;
  List<List<int>> _undoStack = [];

  Future<void> _pickPDF() async {
    setState(() { _errorMsg = null; });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      try {
        final bytes = await file.readAsBytes();
        final doc = sf.PdfDocument(inputBytes: bytes);
        setState(() {
          _pdfFile = file;
          _pdfBytes = bytes;
          _pageCount = doc.pages.count;
          _pageOrder = List.generate(doc.pages.count, (i) => i);
          _undoStack.clear();
        });
        doc.dispose();
      } catch (e) {
        setState(() { _errorMsg = 'Failed to open PDF.'; });
      }
    }
  }

  Future<void> _saveReorderedPDF() async {
    if (_pdfFile == null) return;
    setState(() { _isProcessing = true; });
    try {
      final bytes = await _pdfFile!.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      final newDoc = sf.PdfDocument();
      for (int i in _pageOrder) {
        final template = doc.pages[i].createTemplate();
        final page = newDoc.pages.add();
        page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      final output = await _getOutputFile();
      final savedBytes = await newDoc.save();
      await output.writeAsBytes(savedBytes);
      // Save to My PDFs
      final fileName = 'reordered_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await MyPdfsStorage.savePdfToMyPdfs(fileName, savedBytes);
      // Move to Downloads
      await FileService.movePdfToDownload(output.path, fileName);
      newDoc.dispose();
      doc.dispose();
      // Open the PDF
      await OpenFile.open(output.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved and opened!')),
        );
      }
    } catch (e) {
      setState(() { _errorMsg = 'Failed to save PDF.'; });
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  Future<File> _getOutputFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final name = 'reordered_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return File('${dir.path}/$name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder PDF Pages'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Pick PDF'),
              onPressed: _isProcessing ? null : _pickPDF,
            ),
            if (_pdfFile != null) ...[
              const SizedBox(height: 20),
              Text('Drag to reorder pages:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      // Save current order for undo
                      _undoStack.add(List.from(_pageOrder));
                      if (newIndex > oldIndex) newIndex--;
                      final item = _pageOrder.removeAt(oldIndex);
                      _pageOrder.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < _pageOrder.length; i++)
                      Card(
                        key: ValueKey('page_${_pageOrder[i]}'),
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                        child: ListTile(
                          leading: _pdfBytes != null
                              ? SizedBox(
                                  width: 60,
                                  height: 80,
                                  child: PdfPageThumbnail(
                                    pdfBytes: _pdfBytes!,
                                    pageNumber: _pageOrder[i] + 1,
                                    height: 80,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 32),
                          title: Text('Page ${_pageOrder[i] + 1}'),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_isProcessing ? 'Saving...' : 'Save Reordered PDF'),
                      onPressed: _isProcessing ? null : _saveReorderedPDF,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                    onPressed: _undoStack.isNotEmpty && !_isProcessing
                        ? () {
                            setState(() {
                              _pageOrder = _undoStack.removeLast();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  ),
                ],
              ),
            ],
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
