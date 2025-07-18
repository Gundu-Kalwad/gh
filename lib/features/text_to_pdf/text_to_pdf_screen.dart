
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart';
import '../../services/text_to_pdf_service.dart';
import 'package:open_file/open_file.dart';
import '../../providers/pdf_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../my_pdfs/my_pdfs_storage.dart';
import '../../services/file_service.dart';

class TextToPdfScreen extends ConsumerStatefulWidget {
  const TextToPdfScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TextToPdfScreen> createState() => _TextToPdfScreenState();
}

class _TextToPdfScreenState extends ConsumerState<TextToPdfScreen> {
  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  String? _errorMsg;


  Future<void> _pickFile() async {
    setState(() {
      _errorMsg = null;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx', 'doc'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to pick file.';
      });
    }
  }

  Future<void> _createPdf() async {
    if (_selectedFile == null) return;
    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });
    try {
      final ext = _selectedFile!.extension?.toLowerCase();
      String text = '';
      if (ext == 'txt') {
        text = await File(_selectedFile!.path!).readAsString();
      } else if (ext == 'docx') {
        final bytes = await File(_selectedFile!.path!).readAsBytes();
        text = docxToText(bytes);
      } else if (ext == 'doc') {
        setState(() {
          _isProcessing = false;
          _errorMsg = 'Legacy .doc files are not supported. Please use .txt or .docx.';
        });
        return;
      } else {
        setState(() {
          _isProcessing = false;
          _errorMsg = 'Unsupported file type.';
        });
        return;
      }
      if (text.trim().isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMsg = 'No text found in the selected file.';
        });
        return;
      }
      final pdfBytes = await TextToPdfService.createPdfFromText(text, title: _selectedFile!.name);
      final pdfName = (_selectedFile!.name.split('.').first) + '.pdf';
      final pdfProvider = ref.read(pdfListProvider.notifier);
      // Save to My PDFs
      await MyPdfsStorage.savePdfToMyPdfs(pdfName, pdfBytes);
      // Save to Downloads/External Storage
      final document = await pdfProvider.savePdfFromBytes(pdfBytes, pdfName);
      if (document != null) {
        await FileService.movePdfToDownload(document.path, pdfName);
        await OpenFile.open(document.path);
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _errorMsg = 'Failed to save PDF.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Failed to create PDF.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to PDF'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.description, size: 48, color: Colors.teal.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Convert your text or Word documents to PDF in one tap.',
                      style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Select File (.txt, .docx, .doc)'),
              onPressed: _isProcessing ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),
            if (_selectedFile != null)
              Card(
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: ListTile(
                  leading: Icon(Icons.insert_drive_file, color: Colors.teal.shade700, size: 32),
                  title: Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${_selectedFile!.extension?.toUpperCase() ?? ''}  •  ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.redAccent),
                    tooltip: 'Clear',
                    onPressed: _isProcessing ? null : () => setState(() => _selectedFile = null),
                  ),
                ),
              ),
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: LinearProgressIndicator(minHeight: 5, color: Colors.teal.shade400),
              ),
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 28),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  _isProcessing ? 'Creating PDF...' : 'Create PDF',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: (!_isProcessing && _selectedFile != null) ? _createPdf : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
