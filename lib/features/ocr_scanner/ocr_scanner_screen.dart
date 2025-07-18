import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ocr_service.dart';
import '../../services/text_to_pdf_service.dart';
import '../../providers/pdf_provider.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  File? _selectedImage;
  String _extractedText = '';
  bool _isProcessing = false;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Section
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.document_scanner, color: Colors.green, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'OCR Scan',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _captureFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Image Preview or Placeholder
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _selectedImage != null
                    ? Column(
                        children: [
                          const Text(
                            'Selected Image',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _extractText,
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.text_fields),
                            label: Text(_isProcessing ? 'Processing...' : 'Extract Text'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Text(
                            'No Image Selected',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                              color: Colors.grey[100],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.image_outlined, color: Colors.grey, size: 48),
                                  SizedBox(height: 8),
                                  Text('Please select or capture an image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Extracted Text Section
            if (_extractedText.isNotEmpty) ...[
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_snippet_outlined, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Extracted Text',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            tooltip: 'Copy Text',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _textController.text));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            tooltip: 'Clear Text',
                            onPressed: () {
                              setState(() {
                                _textController.clear();
                                _extractedText = '';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Extracted text will appear here...',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'PDF Title',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Save as PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isProcessing ? null : _saveToPdf,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Instructions Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Capture or select an image containing text\n'
                      '2. Tap "Extract Text" to perform OCR\n'
                      '3. Review the extracted text if needed\n'
                      '4. Add a title and save as PDF\n'
                      '5. PDF will be saved to app data and can be moved to downloads',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isProcessing = true);

    try {
      final image = await OcrService.captureImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedText = '';
          _textController.clear();
          _titleController.clear();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      final image = await OcrService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedText = '';
          _textController.clear();
          _titleController.clear();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _extractText() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final text = await OcrService.extractTextFromImage(_selectedImage!);
      setState(() {
        _extractedText = text;
        _textController.text = text;
      });

      if (text.isEmpty) {
        _showErrorSnackBar('No text found in the image');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text extracted successfully!')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error extracting text: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToPdf() async {
    if (_textController.text.trim().isEmpty) {
      _showErrorSnackBar('No text to save');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final title =
          _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : 'Scanned Document';

      final pdfBytes = await TextToPdfService.createPdfFromText(
        _textController.text,
        title: title,
      );

      final fileName =
          '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final document = await ref
          .read(pdfListProvider.notifier)
          .savePdfFromBytes(pdfBytes, fileName);

      if (document != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved successfully!')),
        );

        // Ask if user wants to move to downloads
        _showMoveToDownloadDialog(document.id);
      } else {
        _showErrorSnackBar('Failed to save PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving PDF: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareText() async {
    if (_textController.text.trim().isEmpty) {
      _showErrorSnackBar('No text to share');
      return;
    }

    // This would typically use a share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
      ),
    );
  }

  void _showMoveToDownloadDialog(String documentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('PDF Saved'),
            content: const Text(
              'PDF has been saved to app data. Would you like to move it to the downloads folder?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep in App'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(pdfListProvider.notifier)
                      .movePdfToDownload(documentId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'PDF moved to downloads successfully!'
                            : 'Failed to move PDF to downloads',
                      ),
                    ),
                  );
                },
                child: const Text('Move to Downloads'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
