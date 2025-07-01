import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'result_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProcessScreen extends StatefulWidget {
  final List<XFile> images;
  const ProcessScreen({Key? key, required this.images}) : super(key: key);

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  String _selectedFormat = 'PDF';
  double _compressionLevel = 0.8;
  final TextEditingController _titleController = TextEditingController();
  String _outputTitle = '';

  Widget _buildFormatRadio(String format) {
    return Row(
      children: [
        Radio<String>(
          value: format,
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
        ),
        Text(format),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convert Images'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Selected ${widget.images.length} image(s)',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Image.file(
                        File(widget.images[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Title input box
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter Title:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter file name or title',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (val) {
                  setState(() {
                    _outputTitle = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Format:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...['PDF', 'JPG', 'PNG', 'JPEG', 'WEBP'].map((format) =>
                      GestureDetector(
                        onTap: () => setState(() => _selectedFormat = format),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedFormat == format ? Colors.deepPurple : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedFormat == format ? Colors.deepPurple : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              format,
                              style: TextStyle(
                                color: _selectedFormat == format ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ))
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Compression Level:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Slider(
                value: _compressionLevel,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (_compressionLevel * 100).round().toString() + '%',
                onChanged: (value) {
                  setState(() {
                    _compressionLevel = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_outputTitle.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title for the output file.')),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      content: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 20),
                          const Text('Converting...'),
                        ],
                      ),
                    ),
                  );
                  await Future.delayed(const Duration(seconds: 3));
                  String ext = _selectedFormat.toLowerCase();
                  String fileName = _outputTitle.trim();
                  List<String> outputPaths = [];
                  try {
                    Directory? extDir;
                    if (Platform.isAndroid) {
                      extDir = await getExternalStorageDirectory();
                    } else {
                      extDir = await getApplicationDocumentsDirectory();
                    }
                    if (extDir == null) throw Exception('Cannot access storage');
                    final imageConverterDir = Directory(p.join(extDir.path, 'Image Converter'));
                    if (!await imageConverterDir.exists()) {
                      await imageConverterDir.create(recursive: true);
                    }
                    if (_selectedFormat == 'PDF') {
                      final pdf = pw.Document();
                      for (final xfile in widget.images) {
                        final imgBytes = await xfile.readAsBytes();
                        final img = pw.MemoryImage(imgBytes);
                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Center(child: pw.Image(img));
                            },
                          ),
                        );
                      }
                      final pdfPath = p.join(imageConverterDir.path, '$fileName.pdf');
                      final file = File(pdfPath);
                      await file.writeAsBytes(await pdf.save());
                      outputPaths.add(pdfPath);
                    } else {
                      // For images: JPG, PNG, JPEG, WEBP
                      for (int i = 0; i < widget.images.length; i++) {
                        final xfile = widget.images[i];
                        final imgBytes = await xfile.readAsBytes();
                        img.Image? image = img.decodeImage(imgBytes);
                        if (image == null) continue;
                        List<int> encoded;
                        switch (_selectedFormat) {
                          case 'JPG':
                          case 'JPEG':
                            encoded = img.encodeJpg(image, quality: (_compressionLevel * 100).toInt());
                            ext = 'jpg';
                            break;
                          case 'PNG':
                            encoded = img.encodePng(image, level: (9 - (_compressionLevel * 9).toInt()));
                            ext = 'png';
                            break;
                          case 'WEBP':
                            try {
                              final imgBytes = await xfile.readAsBytes();
                              final compressed = await FlutterImageCompress.compressWithList(
                                imgBytes,
                                format: CompressFormat.webp,
                                quality: (_compressionLevel * 100).toInt(),
                              );
                              final imgPath = p.join(
                                imageConverterDir.path,
                                '$fileName${widget.images.length > 1 ? '_${i+1}' : ''}.webp',
                              );
                              final file = File(imgPath);
                              await file.writeAsBytes(compressed);
                              outputPaths.add(imgPath);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('WEBP encoding failed: ' + e.toString())),
                              );
                            }
                            continue;

                          default:
                            encoded = img.encodeJpg(image);
                        }
                        final imgPath = p.join(
                          imageConverterDir.path,
                          '$fileName${widget.images.length > 1 ? '_${i+1}' : ''}.$ext',
                        );
                        final file = File(imgPath);
                        await file.writeAsBytes(encoded);
                        outputPaths.add(imgPath);
                      }
                    }

                    Navigator.of(context, rootNavigator: true).pop(); // Dismiss progress dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResultScreen(
                          filePaths: outputPaths,
                          format: _selectedFormat,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ' + e.toString())),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  'Convert',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
