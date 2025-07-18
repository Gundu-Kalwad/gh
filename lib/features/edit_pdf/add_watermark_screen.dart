import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'dart:ui' as ui;
import '../my_pdfs/my_pdfs_storage.dart';
import 'package:path_provider/path_provider.dart';

class AddWatermarkScreen extends StatefulWidget {
  const AddWatermarkScreen({Key? key}) : super(key: key);

  @override
  State<AddWatermarkScreen> createState() => _AddWatermarkScreenState();
}

class _AddWatermarkScreenState extends State<AddWatermarkScreen> {
  File? _selectedFile;
  String? _outputPath;
  final TextEditingController _watermarkController = TextEditingController();
  final TextEditingController _customPagesController = TextEditingController();
  bool _isProcessing = false;
  String _watermarkScope = 'all'; // 'all', 'custom', 'preview', 'last', 'odd', 'even'

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);
        _outputPath = null;
      });
    }
  }

  List<int> _parseCustomPages(String input, int pageCount) {
    // Accepts input like "1,2,4-6" and returns a zero-based page index list
    final result = <int>[];
    final parts = input.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final range = trimmed.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]);
          final end = int.tryParse(range[1]);
          if (start != null && end != null && start >= 1 && end <= pageCount && start <= end) {
            result.addAll(List.generate(end - start + 1, (i) => start - 1 + i));
          }
        }
      } else {
        final page = int.tryParse(trimmed);
        if (page != null && page >= 1 && page <= pageCount) {
          result.add(page - 1);
        }
      }
    }
    return result.toSet().toList()..sort();
  }

  Future<void> _addWatermark() async {
    
    if (_selectedFile == null) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a PDF file first.')),
      );
      return;
    }
    if (_watermarkController.text.trim().isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text.')),
      );
      return;
    }
    if (_watermarkScope == 'custom' && _customPagesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter custom page numbers.')),
      );
      return;
    }
    setState(() { _isProcessing = true; });
    try {
      
      final bytes = await _selectedFile!.readAsBytes();
      
      final doc = sf.PdfDocument(inputBytes: bytes);
      final watermarkText = _watermarkController.text.trim();
      
      final brush = sf.PdfSolidBrush(sf.PdfColor(255, 0, 0, 128)); // Semi-transparent red
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 36);
      final pen = sf.PdfPen(sf.PdfColor(255, 0, 0, 128)); // Semi-transparent red
      
      List<int> targetPages;
      switch (_watermarkScope) {
        case 'custom':
          targetPages = _parseCustomPages(_customPagesController.text, doc.pages.count);
          if (targetPages.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid custom pages found.')),
            );
            setState(() { _isProcessing = false; });
            return;
          }
          break;
        case 'preview':
          targetPages = [0];
          break;
        case 'last':
          targetPages = [doc.pages.count - 1];
          break;
        case 'odd':
          targetPages = List.generate(doc.pages.count, (i) => i).where((i) => i % 2 == 0).toList();
          break;
        case 'even':
          targetPages = List.generate(doc.pages.count, (i) => i).where((i) => i % 2 == 1).toList();
          break;
        case 'all':
        default:
          targetPages = List.generate(doc.pages.count, (i) => i);
      }
      for (final i in targetPages) {
        final page = doc.pages[i];
        final size = page.getClientSize();
        
        page.graphics.save();
        page.graphics.setTransparency(0.5); // Make it more visible
        page.graphics.drawString(
          watermarkText,
          font,
          brush: brush,
          pen: pen,
          bounds: ui.Rect.fromLTWH(0, size.height / 2 - 40, size.width, 80), // Make it taller to ensure full text visibility
          format: sf.PdfStringFormat(
            alignment: sf.PdfTextAlignment.center,
            lineAlignment: sf.PdfVerticalAlignment.middle,
          ),
        );
        page.graphics.restore();
      }
      final outBytes = await doc.save();
      doc.dispose();
      final fileName = 'watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Save to My PDFs directory
      final myPdfsFile = await MyPdfsStorage.savePdfToMyPdfs(fileName, outBytes);
      
      // Save to Downloads folder
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final downloadsFile = File('${downloadsDir.path}/$fileName');
        await downloadsFile.writeAsBytes(outBytes);
      }
      
      setState(() {
        _outputPath = myPdfsFile.path;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Watermark added! Saved to My PDFs.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(myPdfsFile.path),
          ),
        ),
      );
    } catch (e, st) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add watermark: \\${e}')),
      );
    } finally {
      setState(() { _isProcessing = false; });
    }
  }


  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.water_drop_outlined, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Add Watermark'),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Select PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(_selectedFile == null ? 'Pick PDF' : 'Change PDF'),
                        onPressed: _isProcessing ? null : _pickPDF,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text('Selected: ${_selectedFile!.path.split(Platform.pathSeparator).last}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Watermark Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _watermarkController,
                        decoration: const InputDecoration(
                          labelText: 'Enter watermark text',
                          border: OutlineInputBorder(),
                          helperText: 'This text will appear as a watermark on selected pages.',
                        ),
                        enabled: !_isProcessing,
                      ),
                      const SizedBox(height: 12),
                      const Text('Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Card(
                        color: Colors.blue.shade50,
                        child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: 0.3,
                            child: Text(
                              _watermarkController.text.isEmpty
                                  ? 'Watermark Sample'
                                  : _watermarkController.text,
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Pages to Watermark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('All Pages'),
                              selected: _watermarkScope == 'all',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'all'); },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Preview (First)'),
                              selected: _watermarkScope == 'preview',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'preview'); },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Last Page'),
                              selected: _watermarkScope == 'last',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'last'); },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Odd Pages'),
                              selected: _watermarkScope == 'odd',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'odd'); },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Even Pages'),
                              selected: _watermarkScope == 'even',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'even'); },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Custom Pages'),
                              selected: _watermarkScope == 'custom',
                              onSelected: _isProcessing ? null : (v) { if (v) setState(() => _watermarkScope = 'custom'); },
                            ),
                          ],
                        ),
                      ),
                      if (_watermarkScope == 'custom') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customPagesController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Pages (e.g. 1,2,4-6)',
                            border: OutlineInputBorder(),
                            helperText: 'Enter page numbers or ranges separated by commas.',
                          ),
                          enabled: !_isProcessing,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.opacity),
                label: Text(_isProcessing ? 'Processing...' : 'Add Watermark'),
                onPressed: (_selectedFile != null && !_isProcessing && _watermarkController.text.trim().isNotEmpty && (_watermarkScope == 'all' || _customPagesController.text.trim().isNotEmpty))
                    ? _addWatermark
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProcessing ? Colors.blue.shade200 : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(),
              ],
              if (_outputPath != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Success!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 6),
                        Text('Saved to: $_outputPath', style: const TextStyle(color: Colors.green)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open PDF'),
                          onPressed: () => OpenFile.open(_outputPath!),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // Padding
    ); // Scaffold
  }
}

