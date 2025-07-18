import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImagesToPdfService {
  static Future<String> createPdfFromImages(List<File> images, String pdfName) async {
    final pdf = pw.Document();
    for (final imageFile in images) {
      final image = pw.MemoryImage(await imageFile.readAsBytes());
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(child: pw.Image(image)),
        ),
      );
    }
    final dir = await getApplicationDocumentsDirectory();
    final pdfPath = '${dir.path}/$pdfName-${const Uuid().v4()}.pdf';
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfPath;
  }
}
