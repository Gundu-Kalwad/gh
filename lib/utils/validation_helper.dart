class ValidationHelper {
  // Validate if text is not empty
  static bool isTextValid(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  // Validate file name
  static bool isValidFileName(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) return false;

    // Check for invalid characters
    final invalidChars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
    for (final char in invalidChars) {
      if (fileName.contains(char)) return false;
    }

    return true;
  }

  // Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    }

    if (password.length < 4) {
      return 'Password must be at least 4 characters long';
    }

    return null; // Valid password
  }

  // Validate PDF file extension
  static bool isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  // Validate image file extension
  static bool isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif'];
    final lowerFileName = fileName.toLowerCase();

    return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
  }

  // Sanitize file name
  static String sanitizeFileName(String fileName) {
    // Remove invalid characters
    final invalidChars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
    String sanitized = fileName;

    for (final char in invalidChars) {
      sanitized = sanitized.replaceAll(char, '_');
    }

    // Remove multiple spaces and trim
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Ensure it's not empty
    if (sanitized.isEmpty) {
      sanitized = 'untitled';
    }

    return sanitized;
  }

  // Validate file size (in MB)
  static bool isValidFileSize(
    double fileSizeInMB, {
    double maxSizeInMB = 50.0,
  }) {
    return fileSizeInMB <= maxSizeInMB;
  }

  // Format file size for display
  static String formatFileSize(double fileSizeInMB) {
    if (fileSizeInMB < 1.0) {
      return '${(fileSizeInMB * 1024).toStringAsFixed(0)} KB';
    } else {
      return '${fileSizeInMB.toStringAsFixed(1)} MB';
    }
  }
}
