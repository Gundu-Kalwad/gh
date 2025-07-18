import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/images_to_pdf_service.dart';
import '../../services/file_service.dart';
import '../../models/pdf_document.dart';
import '../../providers/pdf_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import '../my_pdfs/my_pdfs_storage.dart';
import '../my_pdfs/my_pdfs_screen.dart' as my_pdfs;

class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<File> _selectedImages = [];
  final TextEditingController _pdfNameController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _pickImages() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        if (!await Permission.photos.request().isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied to access images.')),
          );
          return;
        }
      } else {
        // Android < 13
        if (!await Permission.storage.request().isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied to access images.')),
          );
          return;
        }
      }
    } else if (Platform.isIOS) {
      if (!await Permission.photos.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access photos.')),
        );
        return;
      }
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _takePicture() async {
    // Request camera permission
    if (!await Permission.camera.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied to use camera.')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _createPdf() async {
    if (_selectedImages.isEmpty || _pdfNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select images and enter PDF name.')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final pdfPath = await ImagesToPdfService.createPdfFromImages(
        _selectedImages,
        _pdfNameController.text.trim(),
      );
      final fileName = _pdfNameController.text.trim() + '.pdf';
      final pdfFile = File(pdfPath);
      final pdfBytes = await pdfFile.readAsBytes();
      // Save in My PDFs section
      final myPdfFile = await MyPdfsStorage.savePdfToMyPdfs(fileName, pdfBytes);
      // Save to external Downloads directory
      await FileService.movePdfToDownload(myPdfFile.path, fileName);
      final pdfDocument = PdfDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: myPdfFile.path,
        createdAt: DateTime.now(),
        pageCount: null,
        isPasswordProtected: false,
        fileSizeInMB: myPdfFile.lengthSync() / (1024 * 1024),
      );
      if (mounted) {
        // Add to provider
        final container = ProviderScope.containerOf(context, listen: false);
        await container.read(pdfListProvider.notifier).addPdf(pdfDocument);
        setState(() {
          _selectedImages.clear();
          _pdfNameController.clear();
        });
        // Automatically open the PDF in the viewer after saving
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewPage(document: pdfDocument),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF saved in My PDFs and Downloads!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create PDF.')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _pdfNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Images to PDF'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How it works',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('How to use'),
                content: const Text(
                  '1. Pick or capture images.\n2. Enter a PDF name.\n3. Tap Create PDF.\nYour PDF will appear in My PDFs.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isProcessing ? null : _pickImages,
                    icon: const Icon(Icons.image, size: 28),
                    label: const Text('Pick Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isProcessing ? null : _takePicture,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _selectedImages.isNotEmpty
                  ? SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, idx) => Stack(
                          children: [
                            Card(
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                width: 100,
                                height: 130,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Image.file(
                                  _selectedImages[idx],
                                  width: 100,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.redAccent,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  onPressed: _isProcessing
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedImages.removeAt(idx);
                                          });
                                        },
                                  splashRadius: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No images selected',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pick images from gallery or use the camera',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pdfNameController,
              decoration: InputDecoration(
                labelText: 'PDF Name',
                hintText: 'Enter a name for your PDF',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _pdfNameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _pdfNameController.clear()),
                    )
                  : null,
              ),
              textInputAction: TextInputAction.done,
              enabled: !_isProcessing,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _isProcessing ? null : _createPdf(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                onPressed: _isProcessing || _pdfNameController.text.trim().isEmpty || _selectedImages.isEmpty
                  ? null
                  : () async {
                      await _createPdf();
                      if (mounted && !_isProcessing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF created and saved in My PDFs!')),
                        );
                      }
                    },
                icon: const Icon(Icons.picture_as_pdf, size: 30),
                label: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
