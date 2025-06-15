import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_coding_studio/logic/template/template_model.dart';
import 'package:pro_coding_studio/logic/template/template_provider.dart';

/// Screen for showing template details and handling download
class TemplateDetailsScreen extends ConsumerStatefulWidget {
  final Template template;
  final String projectDirectory; // Directory where template will be downloaded
  final String originalDirectory; // User's selected directory
  final bool isContentUri; // Whether the original directory is a content URI

  const TemplateDetailsScreen({
    Key? key,
    required this.template,
    required this.projectDirectory,
    required this.originalDirectory,
    required this.isContentUri,
  }) : super(key: key);

  @override
  ConsumerState<TemplateDetailsScreen> createState() => _TemplateDetailsScreenState();
}

class _TemplateDetailsScreenState extends ConsumerState<TemplateDetailsScreen> {
  bool _isDownloading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadProgress = ref.watch(templateDownloadProgressProvider);
    final downloadStatus = ref.watch(templateDownloadStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        title: Text(widget.template.name),
        backgroundColor: const Color(0xFF22242A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template preview image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.template.previewImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2A2E3A),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Template description
            Text(
              widget.template.description,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            
            const SizedBox(height: 32),
            
            const SizedBox(height: 16),
            
            
            // Project location
            Text(
              'Project Location: ${widget.projectDirectory}',
              style: const TextStyle(color: Colors.white70),
            ),
            
            const SizedBox(height: 32),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Download progress
            if (_isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value: downloadProgress,
                    backgroundColor: const Color(0xFF2A2E3A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF64FFDA)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    downloadStatus,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Download button
            ElevatedButton(
              onPressed: _isDownloading ? null : _downloadTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isDownloading ? 'Downloading...' : 'Download Template'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final String projectDir = widget.projectDirectory;
    
    setState(() {
      _isDownloading = true;
      _errorMessage = '';
    });
    
    // Reset progress indicators
    ref.read(templateDownloadProgressProvider.notifier).state = 0.0;
    ref.read(templateDownloadStatusProvider.notifier).state = 'Preparing...';
    
    // For regular file paths, verify the directory exists
    if (!projectDir.startsWith('content:')) {
      try {
        // Make sure the directory exists
        final directory = Directory(projectDir);
        if (!await directory.exists()) {
          debugPrint('Creating directory: $projectDir');
          await directory.create(recursive: true);
        }
        
        // Test write access
        final testFile = File('$projectDir/test_write.txt');
        await testFile.writeAsString('Test write access');
        await testFile.delete();
        debugPrint('Successfully verified write access to directory');
      } catch (e) {
        debugPrint('ERROR: Cannot access directory: $e');
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Cannot access the selected directory: $e';
          });
        }
        return;
      }
    }
    
    final templateService = ref.read(templateServiceProvider);
    final template = widget.template;
    
    try {
      debugPrint('Starting template download to directory: $projectDir');
      
      final success = await templateService.downloadTemplate(
        template: template,
        targetDirectory: projectDir,
        onProgress: (progress, status) {
          debugPrint('Download progress: $progress, status: $status');
          ref.read(templateDownloadProgressProvider.notifier).state = progress;
          ref.read(templateDownloadStatusProvider.notifier).state = status;
        },
      );
      
      if (success) {
        debugPrint('Template download successful!');
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template downloaded successfully!')),
          );
          
          // If we're using a content URI, show a dialog to inform the user
          // that they may need to refresh their file explorer to see the files
          if (projectDir.startsWith('content:')) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Template Downloaded'),
                content: Text(
                  'The template has been downloaded to your selected folder. '
                  'You may need to refresh your file explorer to see the new files.\n\n'
                  'The files were extracted to: $projectDir'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          
          // Close this screen and return to the previous screen
          Navigator.pop(context);
        }
      } else {
        debugPrint('Template download failed with success=false');
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Failed to download template. Check logs for details.';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download template')),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception during template download: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Error: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String projectPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        title: const Text('Template Downloaded', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The template has been successfully downloaded and extracted.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Project Location: $projectPath',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            child: const Text('Open Project'),
          ),
        ],
      ),
    );
  }
}
