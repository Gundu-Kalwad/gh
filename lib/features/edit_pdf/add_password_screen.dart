import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../my_pdfs/my_pdfs_storage.dart';

class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({Key? key}) : super(key: key);

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.first.path!);

      });
    }
  }

  Future<void> _addPassword() async {
    if (_selectedFile == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF and enter a password.')),
      );
      return;
    }
    setState(() { _isProcessing = true; });
    try {
      final bytes = await _selectedFile!.readAsBytes();
      final doc = sf.PdfDocument(inputBytes: bytes);
      doc.security.userPassword = _passwordController.text;
      final outBytes = await doc.save();
      doc.dispose();
      final fileName = 'protected_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final myPdfsFile = await MyPdfsStorage.savePdfToMyPdfs(fileName, outBytes);
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final downloadsFile = File('${downloadsDir.path}/$fileName');
        await downloadsFile.writeAsBytes(outBytes);
      }
      // No need to set _outputPath anymore, just proceed.
      // Automatically open the PDF after saving
      await OpenFile.open(myPdfsFile.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password added! PDF saved to My PDFs and opened.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add password: $e')),
      );
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Password to PDF'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline, size: 54, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        'Protect Your PDF',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.95),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a password to restrict access to your PDF file.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: Text(_selectedFile == null ? 'Select PDF' : 'Change PDF'),
                          onPressed: _isProcessing ? null : _pickPDF,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf, color: Colors.indigo, size: 32),
                              title: Text(_selectedFile!.path.split(Platform.pathSeparator).last),
                              subtitle: const Text('PDF selected'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Enter Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.vpn_key),
                            filled: true,
                            fillColor: Colors.grey[100],
                            hintText: 'Password',
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.lock),
                            label: Text(_isProcessing ? 'Processing...' : 'Add Password'),
                            onPressed: _isProcessing ? null : _addPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isProcessing)
                          const Center(child: Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: CircularProgressIndicator(),
                          )),
                        const SizedBox(height: 6),
                        Text(
                          'Tip: Use a strong password to keep your PDF secure.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
