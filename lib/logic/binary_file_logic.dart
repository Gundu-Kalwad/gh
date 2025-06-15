import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';

/// Provider to determine if the current file is a binary file
final isBinaryFileProvider = Provider.family<bool, DocumentFileInfo>((ref, file) {
  final fileName = file.name.toLowerCase();
  
  // List of binary file extensions
  final binaryExtensions = [
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.ico', '.svg', // Images
    '.zip', '.rar', '.7z', '.tar', '.gz', '.jar', '.war', // Archives
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', // Documents
    '.mp3', '.mp4', '.avi', '.mov', '.flv', '.wmv', '.wav', '.ogg', // Media
    '.exe', '.dll', '.so', '.dylib', '.bin', '.dat', // Executables and binary data
    '.db', '.sqlite', '.mdb', // Databases
    '.ttf', '.otf', '.woff', '.woff2', // Fonts
    '.class', '.pyc', '.pyo', // Compiled code
    '.webp', '.tiff', '.psd' // More image formats
  ];
  
  // Check if file extension matches any binary extension
  for (final ext in binaryExtensions) {
    if (fileName.endsWith(ext)) {
      return true;
    }
  }
  
  return false;
});

/// Provider to determine if the current file is an image file
final isImageFileProvider = Provider.family<bool, DocumentFileInfo>((ref, file) {
  final fileName = file.name.toLowerCase();
  
  // List of image file extensions
  final imageExtensions = [
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.ico', '.svg',
    '.webp', '.tiff', '.psd'
  ];
  
  // Check if file extension matches any image extension
  for (final ext in imageExtensions) {
    if (fileName.endsWith(ext)) {
      return true;
    }
  }
  
  return false;
});
