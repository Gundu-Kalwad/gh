class PdfDocument {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final int? pageCount;
  final bool isPasswordProtected;
  final double? fileSizeInMB;

  PdfDocument({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.pageCount,
    this.isPasswordProtected = false,
    this.fileSizeInMB,
  });

  PdfDocument copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    int? pageCount,
    bool? isPasswordProtected,
    double? fileSizeInMB,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      pageCount: pageCount ?? this.pageCount,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      fileSizeInMB: fileSizeInMB ?? this.fileSizeInMB,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'createdAt': createdAt.toIso8601String(),
      'pageCount': pageCount,
      'isPasswordProtected': isPasswordProtected,
      'fileSizeInMB': fileSizeInMB,
    };
  }

  factory PdfDocument.fromJson(Map<String, dynamic> json) {
    return PdfDocument(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      createdAt: DateTime.parse(json['createdAt']),
      pageCount: json['pageCount'],
      isPasswordProtected: json['isPasswordProtected'] ?? false,
      fileSizeInMB: json['fileSizeInMB'],
    );
  }
}
