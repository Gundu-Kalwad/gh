import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';

/// A widget that can display various types of binary files
class BinaryFileViewer extends ConsumerStatefulWidget {
  final DocumentFileInfo file;
  
  const BinaryFileViewer({Key? key, required this.file}) : super(key: key);

  @override
  ConsumerState<BinaryFileViewer> createState() => _BinaryFileViewerState();
}

class _BinaryFileViewerState extends ConsumerState<BinaryFileViewer> {
  Uint8List? _fileBytes;
  bool _isLoading = true;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadFileBytes();
  }
  
  Future<void> _loadFileBytes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final bytes = await DocumentFileHandler.readFileBytes(widget.file.uri);
      
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorMessage = 'Could not read file or file is empty';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _fileBytes = Uint8List.fromList(bytes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading file: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }
    
    if (_fileBytes == null) {
      return const Center(child: Text('No data available', style: TextStyle(color: Colors.white)));
    }
    
    // Determine file type based on extension
    final fileName = widget.file.name.toLowerCase();
    
    // Image files
    if (fileName.endsWith('.png') || 
        fileName.endsWith('.jpg') || 
        fileName.endsWith('.jpeg') || 
        fileName.endsWith('.gif') || 
        fileName.endsWith('.webp') || 
        fileName.endsWith('.bmp')) {
      return _buildImageViewer();
    }
    
    // PDF files - would require a PDF viewer package
    if (fileName.endsWith('.pdf')) {
      return _buildUnsupportedFormatMessage('PDF');
    }
    
    // For other binary files, show a hex viewer
    return _buildHexViewer();
  }
  
  Widget _buildImageViewer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF23262F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  widget.file.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    _fileBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Error loading image',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHexViewer() {
    // Convert bytes to hex representation
    final hexStrings = <String>[];
    for (int i = 0; i < _fileBytes!.length; i += 16) {
      final end = i + 16 > _fileBytes!.length ? _fileBytes!.length : i + 16;
      final chunk = _fileBytes!.sublist(i, end);
      
      // Create hex representation
      final hexLine = chunk.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
      
      // Create ASCII representation (only for printable characters)
      final asciiLine = chunk.map((byte) {
        if (byte >= 32 && byte <= 126) { // Printable ASCII range
          return String.fromCharCode(byte);
        } else {
          return '.';
        }
      }).join('');
      
      // Combine both with the offset
      hexStrings.add('${i.toRadixString(16).padLeft(8, '0')}: $hexLine${' ' * (48 - hexLine.length)} | $asciiLine');
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF23262F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Binary File: ${widget.file.name}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(color: Color(0xFF3A3F4B)),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    hexStrings.join('\n'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'FiraMono',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUnsupportedFormatMessage(String format) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF23262F),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_present, size: 64, color: Color(0xFF64FFDA)),
              const SizedBox(height: 16),
              Text(
                '$format Viewer',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'File: ${widget.file.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              const Text(
                'This file format is not currently supported for preview.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can still edit or download this file.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
