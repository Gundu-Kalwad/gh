import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pro_coding_studio/logic/template/template_model.dart';
import 'package:pro_coding_studio/special_storage_handling/document_file_handler.dart';

/// Provider for the template service
final templateServiceProvider = Provider<TemplateService>((ref) {
  return TemplateService();
});

/// Provider for the list of template categories
final templateCategoriesProvider = FutureProvider<List<TemplateCategory>>((ref) async {
  final service = ref.read(templateServiceProvider);
  return await service.fetchTemplateCategories();
});

/// Provider for the currently selected category
final selectedCategoryProvider = StateProvider<TemplateCategory?>((ref) => null);

/// Provider for the currently selected template
final selectedTemplateProvider = StateProvider<Template?>((ref) => null);

/// Provider for the download progress
final templateDownloadProgressProvider = StateProvider<double>((ref) => 0.0);

/// Provider for the download status message
final templateDownloadStatusProvider = StateProvider<String>((ref) => '');

/// Service class for template operations
class TemplateService {
  static const String _repoOwner = 'PRAJWALSINGHKALWAD';
  static const String _repoName = 'Pro-Coding-Studio-Templates';
  static const String _manifestPath = 'manifest.json';
  
  /// Fetch template categories from the GitHub repository
  Future<List<TemplateCategory>> fetchTemplateCategories() async {
    try {
      // Fetch the manifest file from GitHub
      final url = 'https://raw.githubusercontent.com/$_repoOwner/$_repoName/main/$_manifestPath';
      debugPrint('Fetching manifest from: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        debugPrint('Manifest Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
      
      debugPrint('Manifest loaded successfully');
      
      // Parse the manifest JSON
      final Map<String, dynamic> manifestData = jsonDecode(response.body);
      final List<dynamic> categoriesData = manifestData['categories'];
      
      // Convert to model objects
      return categoriesData.map((data) => TemplateCategory.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }
  
  /// Downloads a template from GitHub and extracts it to the target directory
  Future<bool> downloadTemplate({
    required Template template,
    required String targetDirectory,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      onProgress(0.0, 'Preparing to download...');
      
      // Check if the target directory is a content URI (Android Storage Access Framework)
      final bool isContentUri = targetDirectory.startsWith('content:');
      
      // Print detailed information about the target directory
      debugPrint('==================== TEMPLATE DOWNLOAD DETAILS ====================');
      debugPrint('Target directory: $targetDirectory');
      debugPrint('Is content URI: $isContentUri');
      
      // Prepare possible ZIP URLs for the template
      final String templatePath = template.path;
      final bool isFullUrl = templatePath.startsWith('http');
      final List<String> possibleZipUrls = [];
      
      if (isFullUrl) {
        possibleZipUrls.add(templatePath);
        debugPrint('Using direct URL from manifest: $templatePath');
      } else {
        possibleZipUrls.addAll([
          // Option 1: Template path with .zip extension
          'https://raw.githubusercontent.com/$_repoOwner/$_repoName/main/$templatePath.zip',
          
          // Option 2: ZIP file inside the template directory
          'https://raw.githubusercontent.com/$_repoOwner/$_repoName/main/$templatePath/template.zip',
          
          // Option 3: ZIP file with template ID name
          'https://raw.githubusercontent.com/$_repoOwner/$_repoName/main/templates/${template.id}.zip',
        ]);
      }
      
      http.Response? zipResponse;
      String? successfulUrl;
      
      // Try each URL until we find one that works
      for (final zipUrl in possibleZipUrls) {
        debugPrint('Trying to download ZIP from: $zipUrl');
        
        try {
          final response = await http.get(Uri.parse(zipUrl));
          debugPrint('ZIP download response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            zipResponse = response;
            successfulUrl = zipUrl;
            debugPrint('ZIP file found at: $zipUrl');
            debugPrint('ZIP file size: ${response.bodyBytes.length} bytes');
            break;
          } else {
            debugPrint('ZIP not found at: $zipUrl');
          }
        } catch (e) {
          debugPrint('Error trying URL $zipUrl: $e');
          // Continue to the next URL
        }
      }
      
      if (zipResponse == null || successfulUrl == null) {
        throw Exception('Could not find template ZIP file at any of the expected locations. Please check that the ZIP file exists in your GitHub repository.');
      }
      
      debugPrint('Successfully downloaded ZIP from: $successfulUrl');
      debugPrint('ZIP file size: ${zipResponse.bodyBytes.length} bytes');
      
      onProgress(0.8, 'Extracting files...');
      
      // Handle content URIs differently than regular file paths
      if (isContentUri) {
        // For content URIs, we need to use the Document API
        debugPrint('Using Document API for content URI: $targetDirectory');
        
        // Create a temporary file to download the ZIP to
        final tempDir = await Directory.systemTemp.createTemp('template_download');
        final zipFilePath = '${tempDir.path}/template.zip';
        
        // Save the zip file to temporary location
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(zipResponse.bodyBytes);
        debugPrint('Template ZIP file saved to temporary location: $zipFilePath');
        
        try {
          // Try to use native method to extract the ZIP directly to the content URI
          final success = await DocumentFileHandler.extractZipToContentUri(
            zipFilePath, 
            targetDirectory
          );
          
          // Clean up temporary files
          await zipFile.delete();
          await tempDir.delete(recursive: true);
          
          if (success) {
            debugPrint('Successfully extracted template to content URI using native method');
            onProgress(1.0, 'Template downloaded and extracted successfully!');
            return true;
          } else {
            throw Exception('Failed to extract template to content URI');
          }
        } catch (e) {
          debugPrint('Native extraction failed: $e');
          debugPrint('Falling back to temporary directory approach');
          
          // FALLBACK: Use the app's documents directory instead
          try {
            // Extract to a temporary location that we can access
            final appDocDir = await getApplicationDocumentsDirectory();
            final extractDir = '${appDocDir.path}/templates/${template.id}_${DateTime.now().millisecondsSinceEpoch}';
            
            // Create the directory if it doesn't exist
            final extractDirObj = Directory(extractDir);
            if (!await extractDirObj.exists()) {
              await extractDirObj.create(recursive: true);
            }
            
            // Extract the ZIP file to the temporary location
            final bytes = await zipFile.readAsBytes();
            final archive = ZipDecoder().decodeBytes(bytes);
            
            debugPrint('Extracting ${archive.length} files to temporary location: $extractDir');
            
            for (final file in archive) {
              final filename = file.name;
              
              if (file.isFile) {
                final data = file.content as List<int>;
                final filePath = '$extractDir/$filename';
                
                // Create parent directories if needed
                final fileDirectory = path.dirname(filePath);
                await Directory(fileDirectory).create(recursive: true);
                
                // Write file
                final outFile = File(filePath);
                await outFile.writeAsBytes(data);
              } else {
                // Create directory
                final dirPath = '$extractDir/$filename';
                await Directory(dirPath).create(recursive: true);
              }
            }
            
            // Clean up temporary files
            await zipFile.delete();
            await tempDir.delete(recursive: true);
            
            debugPrint('Successfully extracted template to temporary location');
            debugPrint('Please note: Since we cannot write directly to content URIs without native support,');
            debugPrint('the template has been extracted to: $extractDir');
            
            onProgress(1.0, 'Template downloaded to app storage. See logs for location.');
            return true;
          } catch (fallbackError) {
            debugPrint('Fallback extraction also failed: $fallbackError');
            onProgress(0.0, 'Error: $fallbackError');
            return false;
          }
        }
      }
      
      // For regular file paths, use standard extraction
      final zipFile = File(path.join(targetDirectory, 'template.zip'));
      await zipFile.writeAsBytes(zipResponse.bodyBytes);
      
      // Extract the ZIP file
      final bytes = await zipFile.readAsBytes();
      
      try {
        // Use the archive package to extract the ZIP
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Count the number of files to extract
        int totalFiles = archive.files.where((file) => file.isFile).length;
        int extractedCount = 0;
        
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            final filePath = path.join(targetDirectory, filename);
            
            // Create parent directories if needed
            final parentDir = Directory(path.dirname(filePath));
            if (!await parentDir.exists()) {
              await parentDir.create(recursive: true);
            }
            
            // Write the file
            final outFile = File(filePath);
            await outFile.writeAsBytes(data);
            extractedCount++;
            debugPrint('Extracted ($extractedCount/$totalFiles): $filename to $filePath');
          } else {
            // Create directory
            final dirPath = path.join(targetDirectory, filename);
            final dir = Directory(dirPath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            debugPrint('Created directory: $dirPath');
          }
        }
        
        // Delete the ZIP file after extraction
        await zipFile.delete();
        debugPrint('Deleted ZIP file: ${zipFile.path}');
        
        // Print directory contents after extraction
        try {
          final dirContents = await Directory(targetDirectory).list(recursive: false).toList();
          debugPrint('Directory contents after extraction (${dirContents.length} items):');
          for (final entity in dirContents) {
            debugPrint('- ${path.basename(entity.path)}');
          }
        } catch (e) {
          debugPrint('Error listing directory contents after extraction: $e');
        }
        
        onProgress(1.0, 'Template downloaded and extracted successfully!');
        return true;
      } catch (e) {
        debugPrint('Error extracting ZIP: $e');
        onProgress(0.0, 'Error extracting ZIP file: $e');
        
        // Try to delete the ZIP file if it exists
        try {
          if (await zipFile.exists()) {
            await zipFile.delete();
          }
        } catch (deleteError) {
          debugPrint('Error deleting temporary ZIP file: $deleteError');
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('Error downloading template: $e');
      onProgress(0.0, 'Error: $e');
      return false;
    }
  }
  

}
