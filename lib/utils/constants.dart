class AppConstants {
  static const String appName = 'Hello PDF';
  static const String appVersion = '1.0.0';

  // File related constants
  static const String pdfFolderName = 'hello_pdf_documents';
  static const String metadataFileName = 'documents_metadata.json';

  // Supported file formats
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'bmp',
    'gif',
  ];

  static const List<String> supportedPdfFormats = ['pdf'];

  // App settings
  static const double defaultFontSize = 12.0;
  static const double minFontSize = 8.0;
  static const double maxFontSize = 24.0;

  // Error messages
  static const String errorNoText = 'No text found in the image';
  static const String errorInvalidPdf = 'Invalid PDF file';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorFileNotFound = 'File not found';

  // Success messages
  static const String successPdfGenerated = 'PDF generated successfully!';
  static const String successPasswordAdded = 'Password added successfully!';
  static const String successPasswordRemoved = 'Password removed successfully!';
  static const String successPdfSaved = 'PDF saved successfully!';
}
