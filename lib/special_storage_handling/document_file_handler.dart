import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_info.dart';

/// Handler for platform-specific Storage Access Framework operations
class DocumentFileHandler {
  static const MethodChannel _channel =
      MethodChannel('com.pmk.pro_coding_studio/file_explorer');

  /// Request access to a directory using the Document provider
  static Future<String?> openDocumentTree() async {
    try {
      final String? directoryUri =
          await _channel.invokeMethod('openDocumentTree');
      return directoryUri;
    } on PlatformException catch (e) {
      print('Error opening document tree: ${e.message}');
      return null;
    }
  }

  /// Get the parent URI of a document URI
  static Future<String?> getParentUri(String uri) async {
    try {
      final String? parentUri = await _channel.invokeMethod('getParentUri', {
        'uri': uri,
      });
      return parentUri;
    } on PlatformException catch (e) {
      print('Error getting parent URI: ${e.message}');

      // Fallback method if native method fails
      try {
        // Simple splitting by '/' may not work for all URIs
        // This is a basic fallback that might work in some cases
        final segments = uri.split('/');
        if (segments.length > 1) {
          segments.removeLast();
          return segments.join('/');
        }
      } catch (e) {
        print('Fallback parent URI calculation failed: $e');
      }

      return null;
    }
  }

  /// List files in a directory using DocumentFile API
  static Future<List<DocumentFileInfo>> listFiles(String directoryUri) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('listFiles', {
        'directoryUri': directoryUri,
      });

      return result
          .map((item) =>
              DocumentFileInfo.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } on PlatformException catch (e) {
      print('Error listing files: ${e.message}');
      return [];
    }
  }

  /// Read content from a file using DocumentFile API
  static Future<String> readFileContent(String fileUri) async {
    try {
      final String content = await _channel.invokeMethod('readFileContent', {
        'fileUri': fileUri,
      });
      return content;
    } on PlatformException catch (e) {
      print('Error reading file content: ${e.message}');
      return '';
    }
  }

  /// Read binary content from a file using DocumentFile API
  static Future<List<int>?> readFileBytes(String fileUri) async {
    try {
      // First try to use the native method if available
      try {
        final result = await _channel.invokeMethod('readFileBytes', {
          'fileUri': fileUri,
        });

        if (result is Uint8List) {
          return result;
        } else if (result is List) {
          return result.cast<int>();
        }
      } catch (e) {
        print('Native readFileBytes not available, using fallback: $e');
      }

      // Fallback: Read the file as a base64 string and decode it
      final String base64Content =
          await _channel.invokeMethod('readFileBase64', {
        'fileUri': fileUri,
      });

      if (base64Content.isNotEmpty) {
        return base64Decode(base64Content);
      }

      // If that also fails, try to read the file directly (for file:// URIs)
      if (fileUri.startsWith('file://')) {
        final filePath = fileUri.substring(7); // Remove 'file://' prefix
        final file = File(filePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }

      print('Could not read binary file: $fileUri');
      return null;
    } on PlatformException catch (e) {
      print('Error reading file bytes: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error reading file bytes: $e');
      return null;
    }
  }

  /// Write content to a file
  static Future<bool> writeFileContent(String uri, String content) async {
    try {
      // Validate URI before sending to platform channel
      if (uri.isEmpty) {
        print('Error: Empty URI provided for writeFileContent');
        return false;
      }

      // Ensure URI is properly encoded if it contains special characters
      String safeUri = uri;
      if (!uri.contains('%') && (uri.contains(' ') || uri.contains('#'))) {
        // Only encode if it's not already encoded and contains characters that might need encoding
        try {
          final uriObj = Uri.parse(uri);
          safeUri = uriObj.toString();
        } catch (e) {
          print('Error parsing URI: $e - using original URI');
        }
      }

      final bool success = await _channel.invokeMethod('writeFileContent', {
        'uri': safeUri,
        'content': content,
      });
      return success;
    } on PlatformException catch (e) {
      print('Error writing file content: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error writing file content: $e');
      return false;
    }
  }

  /// Write binary content to a file
  static Future<bool> writeFileBytes(String uri, List<int> bytes) async {
    try {
      // First try to use the native method if available
      try {
        final bool success = await _channel.invokeMethod('writeFileBytes', {
          'uri': uri,
          'bytes': Uint8List.fromList(bytes),
        });
        return success;
      } catch (e) {
        print('Native writeFileBytes not available, using fallback: $e');
      }

      // Fallback: Convert bytes to base64 and write as string
      final String base64Content = base64Encode(bytes);
      final bool success = await _channel.invokeMethod('writeFileContent', {
        'uri': uri,
        'content': base64Content,
        'isBase64': true,
      });

      // If that also fails, try to write the file directly (for file:// URIs)
      if (!success && uri.startsWith('file://')) {
        final filePath = uri.substring(7); // Remove 'file://' prefix
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return true;
      }

      return success;
    } on PlatformException catch (e) {
      print('Error writing file bytes: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error writing file bytes: $e');
      return false;
    }
  }

  /// Create a temporary directory for file operations
  static Future<String?> createTempDirectory() async {
    try {
      // Get the application's temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create a subdirectory for our app
      final appTempDir = Directory('${tempDir.path}/pro_coding_studio_temp');
      if (!await appTempDir.exists()) {
        await appTempDir.create(recursive: true);
      }

      // Create a unique directory for this operation
      final uniqueDir = Directory(
          '${appTempDir.path}/${DateTime.now().millisecondsSinceEpoch}');
      await uniqueDir.create(recursive: true);

      return uniqueDir.path;
    } catch (e) {
      print('Error creating temporary directory: $e');
      return null;
    }
  }

  /// Create a new file in a directory using DocumentFile API
  static Future<DocumentFileInfo?> createFile(
      String directoryUri, String fileName,
      {String mimeType = "text/plain"}) async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('createFile', {
        'directoryUri': directoryUri,
        'fileName': fileName,
        'mimeType': mimeType,
      });

      if (result != null) {
        return DocumentFileInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print('Error creating file: ${e.message}');
      return null;
    }
  }

  /// Create a new directory using DocumentFile API
  static Future<DocumentFileInfo?> createDirectory(
      String directoryUri, String folderName) async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('createDirectory', {
        'directoryUri': directoryUri,
        'folderName': folderName,
      });

      if (result != null) {
        return DocumentFileInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print('Error creating directory: ${e.message}');
      return null;
    }
  }

  /// Open a file directly using the system file picker
  /// This allows selecting a file without first opening a directory
  static Future<DocumentFileInfo?> openDocument() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('openDocument');

      if (result != null) {
        return DocumentFileInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print('Error opening document: ${e.message}');
      return null;
    }
  }

  /// Extract a ZIP file to a directory using the Document API
  /// This is specifically designed to handle content URIs
  static Future<bool> extractZipToContentUri(
      String zipFilePath, String targetDirectoryUri) async {
    try {
      final bool success =
          await _channel.invokeMethod('extractZipToContentUri', {
        'zipFilePath': zipFilePath,
        'targetDirectoryUri': targetDirectoryUri,
      });
      return success;
    } on PlatformException catch (e) {
      print('Error extracting ZIP to content URI: ${e.message}');
      return false;
    }
  }

  /// Delete a file using DocumentFile API
  static Future<bool> deleteFile(String fileUri) async {
    try {
      // Validate URI before sending to platform channel
      if (fileUri.isEmpty) {
        print('Error: Empty URI provided for deleteFile');
        return false;
      }

      // Log the URI we're trying to delete for debugging
      print('Attempting to delete file at URI: $fileUri');

      final bool success = await _channel.invokeMethod('deleteFile', {
        'fileUri': fileUri,
      });

      print('Delete file result: $success');
      return success;
    } on PlatformException catch (e) {
      print('Error deleting file: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error deleting file: $e');
      return false;
    }
  }
}
