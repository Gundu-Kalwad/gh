import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;
import 'package:open_filex/open_filex.dart';

class ResultScreen extends StatefulWidget {
  final List<String> filePaths;
  final String format;
  const ResultScreen({Key? key, required this.filePaths, required this.format}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isGrid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Converted Files'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _isGrid ? 'List View' : 'Grid View',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('Conversion Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.filePaths.isEmpty
                  ? const Center(child: Text('No files found.'))
                  : _isGrid
                      ? GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: widget.filePaths.length,
                          itemBuilder: (context, index) => _buildFileCard(context, index, isGrid: true),
                        )
                      : ListView.builder(
                          itemCount: widget.filePaths.length,
                          itemBuilder: (context, index) => _buildFileCard(context, index, isGrid: false),
                        ),
            ),
            if (widget.filePaths.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share All'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () async {
                    await Share.shareXFiles(widget.filePaths.map((p) => XFile(p)).toList(), text: 'Check out my converted files!');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, int index, {required bool isGrid}) {
    final path = widget.filePaths[index];
    final fileName = path.split(Platform.pathSeparator).last;
    final file = File(path);
    final fileSize = file.existsSync() ? _formatBytes(file.lengthSync()) : '';
    final isPdf = widget.format == 'PDF' || path.toLowerCase().endsWith('.pdf');
    Widget? preview;
    if (!isPdf && file.existsSync()) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: isGrid ? 90 : 50,
          height: isGrid ? 90 : 50,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 48),
        ),
      );
    } else {
      preview = Icon(Icons.picture_as_pdf, color: Colors.red, size: isGrid ? 60 : 40);
    }
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: isGrid ? 0 : 8, horizontal: isGrid ? 0 : 4),
      child: isGrid
          ? InkWell(
              onTap: () => _openFile(context, path),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    preview,
                    const SizedBox(height: 10),
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(fileSize, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Open',
                          onPressed: () => _openFile(context, path),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy Path',
                          onPressed: () => _copyPath(context, path),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: 'Share',
                          onPressed: () async {
                            await Share.shareXFiles([XFile(path)], text: 'Check out my converted file!');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListTile(
              leading: preview,
              title: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('$path\n$fileSize'),
              onTap: () => _openFile(context, path),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy Path',
                    onPressed: () => _copyPath(context, path),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                    onPressed: () async {
                      await Share.shareXFiles([XFile(path)], text: 'Check out my converted file!');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open',
                    onPressed: () => _openFile(context, path),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openFile(BuildContext context, String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  void _copyPath(BuildContext context, String path) {
    Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File path copied!')),
    );
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (bytes != 0) ? (Math.log(bytes) / Math.log(1024)).floor() : 0;
    return ((bytes / Math.pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }
}
