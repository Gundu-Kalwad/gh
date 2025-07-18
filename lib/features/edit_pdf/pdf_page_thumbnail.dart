import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPageThumbnail extends StatelessWidget {
  final Uint8List pdfBytes;
  final int pageNumber;
  final double height;

  const PdfPageThumbnail({
    Key? key,
    required this.pdfBytes,
    required this.pageNumber,
    this.height = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SfPdfViewer.memory(
        pdfBytes,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        initialScrollOffset: Offset(0, (pageNumber - 1) * height),
        pageLayoutMode: PdfPageLayoutMode.single,
        controller: PdfViewerController()
          ..jumpToPage(pageNumber),
      ),
    );
  }
}
