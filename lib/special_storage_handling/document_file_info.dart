class DocumentFileInfo {
  final String uri;
  final String name;
  final bool isDirectory;
  final String? mimeType;
  final int? size;
  final int? lastModified;

  DocumentFileInfo(
      {required this.uri,
      required this.name,
      required this.isDirectory,
      this.mimeType,
      this.size,
      this.lastModified});

  // Helper method to get file extension
  String? get extension {
    final lastDot = name.lastIndexOf('.');
    if (lastDot != -1 && lastDot < name.length - 1) {
      return name.substring(lastDot + 1);
    }
    return null;
  }

  // Factory constructor from map
  factory DocumentFileInfo.fromMap(Map<String, dynamic> map) {
    return DocumentFileInfo(
        uri: map['uri'] as String,
        name: map['name'] as String,
        isDirectory: map['isDirectory'] as bool,
        mimeType: map['mimeType'] as String?,
        size: map['size'] as int?,
        lastModified: map['lastModified'] as int?);
  }
}
