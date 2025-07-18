import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pdf_provider.dart';
import '../../models/pdf_document.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class MyPdfsScreen extends ConsumerWidget {
  const MyPdfsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfs = List<PdfDocument>.from(ref.watch(pdfListProvider))
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('My PDFs')),
      body: pdfs.isEmpty
          ? const Center(child: Text('No PDFs found.'))
          : ListView.builder(
              itemCount: pdfs.length,
              itemBuilder: (context, index) {
                final pdf = pdfs[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(pdf.name),
                  subtitle: Text(
                    'Created: \n${pdf.createdAt}\nSize: ${(pdf.fileSizeInMB?.toStringAsFixed(2) ?? '-')} MB',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewPage(document: pdf),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
