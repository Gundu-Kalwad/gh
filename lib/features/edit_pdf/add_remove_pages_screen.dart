import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../providers/pdf_provider.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import 'package:open_file/open_file.dart';

class AddRemovePagesScreen extends ConsumerStatefulWidget {
  const AddRemovePagesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddRemovePagesScreen> createState() => _AddRemovePagesScreenState();
}

class _AddRemovePagesScreenState extends ConsumerState<AddRemovePagesScreen> {
  PlatformFile? _selectedFile;
  
  sf.PdfDocument? _pdfDoc;
  List<int> _removedPages = [];
  bool _isProcessing = false;
  String? _outputPath;

  @override
  void dispose() {
    _pdfDoc?.dispose();
    super.dispose();
  }

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
          _pdfDoc?.dispose();
          _pdfDoc = doc;
          _removedPages.clear();
          _outputPath = null;
        });
      } catch (e) {
        setState(() {
          _selectedFile = null;
          _pdfDoc = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read PDF: $e')),
        );
      }
    }
  }

  void _toggleRemovePage(int pageIndex) {
    setState(() {
      if (_removedPages.contains(pageIndex)) {
        _removedPages.remove(pageIndex);
      } else {
        _removedPages.add(pageIndex);
      }
    });
  }

  Future<void> _addBlankPage(int position) async {
    if (_pdfDoc == null) return;
    setState(() => _isProcessing = true);
    try {
      _pdfDoc!.pages.insert(position);
      setState(() {});
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _addImagePage(int position) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final imageBytes = await picked.readAsBytes();
      final img = sf.PdfBitmap(imageBytes);
      _pdfDoc!.pages.insert(position);
      final page = _pdfDoc!.pages[position];
      page.graphics.drawImage(img, const Rect.fromLTWH(0, 0, 400, 600));
      setState(() {});
    }
  }

  Future<void> _addPageFromAnotherPDF(int position) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = await File(file.path!).readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      // For simplicity, add the first page of the other PDF
      final template = doc.pages[0].createTemplate();
      _pdfDoc!.pages.insert(position);
      final page = _pdfDoc!.pages[position];
      page.graphics.drawPdfTemplate(template, const Offset(0, 0));
      doc.dispose();
      setState(() {});
    }
  }

  Future<void> _applyChanges() async {
    if (_pdfDoc == null) return;
    setState(() => _isProcessing = true);
    try {
      // Remove marked pages (from last to first to avoid index shift)
      final toRemove = List.of(_removedPages)..sort((a, b) => b.compareTo(a));
      for (final idx in toRemove) {
        _pdfDoc!.pages.removeAt(idx);
      }
      final output = await getTemporaryDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final editedPath = "${output.path}/$fileName";
      final editedFile = File(editedPath);
      final editedBytes = await _pdfDoc!.save();
      await editedFile.writeAsBytes(editedBytes);
      // Register in provider
      final pdfDocument = await ref.read(pdfListProvider.notifier).savePdfFromBytes(
        Uint8List.fromList(editedBytes),
        fileName,
      );
      setState(() {
        _isProcessing = false;
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
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to edit PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Remove Pages'),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a PDF and visually add, remove, or import pages! Tap a page for options.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Select PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isProcessing ? null : _pickPDF,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _pdfDoc == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No PDF selected', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('Tap "Select PDF" to begin.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pdfDoc!.pages.count + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        if (index == _pdfDoc!.pages.count) {
                          // Floating add page button
                          return GestureDetector(
                            onTap: _isProcessing
                                ? null
                                : () async {
                                    await showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.note_add, color: Colors.green),
                                            title: const Text('Add Blank Page at End'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _addBlankPage(_pdfDoc!.pages.count);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.image, color: Colors.orange),
                                            title: const Text('Add Image as Page at End'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _addImagePage(_pdfDoc!.pages.count);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                                            title: const Text('Add Page from Another PDF at End'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _addPageFromAnotherPDF(_pdfDoc!.pages.count);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: Card(
                              color: Colors.green[50],
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: SizedBox(
                                width: 110,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_circle_outline, color: Colors.green, size: 40),
                                      SizedBox(height: 10),
                                      Text('Add Page', style: TextStyle(color: Colors.green)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final isRemoved = _removedPages.contains(index);
                        return Stack(
                          children: [
                            Card(
                              color: isRemoved ? Colors.red[50] : Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isRemoved
                                    ? BorderSide(color: Colors.red.shade300, width: 2)
                                    : BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                              child: SizedBox(
                                width: 110,
                                height: 150,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isRemoved ? Colors.red : Colors.green,
                                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                                      ),
                                      Text(
                                        isRemoved ? 'Will Remove' : 'Page ${index + 1}',
                                        style: TextStyle(
                                          color: isRemoved ? Colors.red : Colors.black87,
                                          fontWeight: isRemoved ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(isRemoved ? Icons.undo : Icons.delete,
                                                color: isRemoved ? Colors.orange : Colors.red),
                                            onPressed: _isProcessing ? null : () => _toggleRemovePage(index),
                                            tooltip: isRemoved ? 'Undo Remove' : 'Remove Page',
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.add_box, color: Colors.green),
                                            onSelected: (value) {
                                              if (value == 'blank') _addBlankPage(index);
                                              if (value == 'image') _addImagePage(index);
                                              if (value == 'pdf') _addPageFromAnotherPDF(index);
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(value: 'blank', child: Text('Add Blank Page Here')),
                                              const PopupMenuItem(value: 'image', child: Text('Add Image as Page')),
                                              const PopupMenuItem(value: 'pdf', child: Text('Add Page from Another PDF')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isRemoved)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '${_removedPages.length} page(s) marked for removal',
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: (_pdfDoc == null || _isProcessing)
                  ? ElevatedButton.icon(
                      key: const ValueKey('disabled'),
                      icon: const Icon(Icons.save),
                      label: Text(_isProcessing ? 'Processing...' : 'Apply Changes'),
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
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Apply Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _applyChanges,
                    ),
            ),
            if (_outputPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Edited PDF saved at: $_outputPath',
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
}
