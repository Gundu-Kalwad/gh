import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MyPdfsStorage {
  static Future<String> getMyPdfsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final myPdfsDir = Directory('${dir.path}/MyPDFs');
    if (!await myPdfsDir.exists()) {
      await myPdfsDir.create(recursive: true);
    }
    return myPdfsDir.path;
  }

  static Future<File> savePdfToMyPdfs(String fileName, List<int> bytes) async {
    final dirPath = await getMyPdfsDirectory();
    final file = File('$dirPath/$fileName');
    return file.writeAsBytes(bytes);
  }
}
