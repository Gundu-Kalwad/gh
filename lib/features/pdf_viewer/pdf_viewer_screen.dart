import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pdf_document.dart';
import '../../providers/pdf_provider.dart';
import 'external_pdf_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfDocuments = ref.watch(pdfListProvider);
    final filteredDocuments = _filterDocuments(pdfDocuments);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My PDFs'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(pdfListProvider.notifier).loadPdfs(),
          ),
        ],
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: getAllExternalPdfs(),
        builder: (context, snapshot) {
          final externalPdfs = snapshot.data ?? [];
          final allPdfs = [
            ...filteredDocuments.map((doc) => {'type': 'app', 'doc': doc}),
            ...externalPdfs.map((file) => {'type': 'external', 'file': file}),
          ];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search PDFs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              // PDF List
              Expanded(
                child: allPdfs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allPdfs.length,
                        itemBuilder: (context, index) {
                          final item = allPdfs[index];
                          if (item['type'] == 'app') {
                            return _buildPdfCard(item['doc'] as PdfDocument);
                          } else {
                            final file = item['file'] as FileSystemEntity;
                            final fileName = file.path.split('/').last;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 32),
                                title: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text(file.path),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'share') {
                                      await Share.shareXFiles([XFile(file.path)], text: fileName);
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete PDF'),
                                          content: Text('Delete "$fileName" from your device?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await File(file.path).delete();
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('PDF deleted successfully')),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Failed to delete PDF')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: ListTile(
                                        leading: Icon(Icons.share),
                                        title: Text('Share'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete),
                                        title: Text('Delete'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Optionally open PDF using a PDF viewer
                                },
                              ),
                            );
                          }
                        },
                      ),
              ),
            ],
          );
        },
      ),

    );
  }

  List<PdfDocument> _filterDocuments(List<PdfDocument> documents) {
    if (_searchQuery.isEmpty) return documents;

    return documents.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No PDFs Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No PDFs match your search'
                : 'Start by scanning documents',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPdfCard(PdfDocument document) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPdf(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // PDF Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red.shade700,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              // PDF Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (document.pageCount != null) ...[
                          Icon(
                            Icons.pages,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${document.pageCount} pages',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (document.fileSizeInMB != null) ...[
                          Icon(
                            Icons.storage,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${document.fileSizeInMB!.toStringAsFixed(1)} MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(document.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (document.isPasswordProtected) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Password Protected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, document),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: ListTile(
                          leading: Icon(Icons.open_in_new),
                          title: Text('Open'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openPdf(PdfDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PdfViewPage(document: document)),
    );
  }

  void _handleMenuAction(String action, PdfDocument document) {
    switch (action) {
      case 'open':
        _openPdf(document);
        break;
      case 'share':
        _sharePdf(document);
        break;
      case 'delete':
        _deletePdf(document);
        break;
    }
  }

  Future<void> _movePdfToDownload(PdfDocument document) async {
    final success = await ref
        .read(pdfListProvider.notifier)
        .movePdfToDownload(document.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'PDF moved to downloads successfully!'
              : 'Failed to move PDF to downloads',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _sharePdf(PdfDocument document) async {
    try {
      await Share.shareXFiles(
        [XFile(document.path)],
        text: document.name,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }

  void _deletePdf(PdfDocument document) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete PDF'),
            content: Text(
              'Are you sure you want to delete "${document.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(pdfListProvider.notifier).removePdf(document.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF deleted successfully')),
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _importPdf() {
    // File picker functionality would be implemented here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import PDF functionality would be implemented here'),
      ),
    );
  }
}

class PdfViewPage extends StatefulWidget {
  final PdfDocument document;

  const PdfViewPage({super.key, required this.document});

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  late PDFViewController _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_isReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.document.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
                _isReady = true;
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page!;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading PDF: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),

          if (!_isReady) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton:
          _isReady
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    backgroundColor:
                        _currentPage > 0 ? Colors.orange : Colors.grey,
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed:
                        _currentPage < _totalPages - 1 ? _nextPage : null,
                    backgroundColor:
                        _currentPage < _totalPages - 1
                            ? Colors.orange
                            : Colors.grey,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              )
              : null,
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pdfController.setPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pdfController.setPage(_currentPage + 1);
    }
  }
}
