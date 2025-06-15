/// Model class for a template category
class TemplateCategory {
  final String id;
  final String name;
  final List<Template> templates;

  TemplateCategory({
    required this.id,
    required this.name,
    required this.templates,
  });

  /// Create a TemplateCategory from JSON data
  factory TemplateCategory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> templatesJson = json['templates'];
    final templates = templatesJson
        .map((templateJson) => Template.fromJson(templateJson))
        .toList();

    return TemplateCategory(
      id: json['id'],
      name: json['name'],
      templates: templates,
    );
  }

  /// Convert TemplateCategory to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'templates': templates.map((template) => template.toJson()).toList(),
    };
  }
}

/// Model class for a template
class Template {
  final String id;
  final String name;
  final String description;
  final String path;
  final String previewImageUrl;

  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.path,
    required this.previewImageUrl,
  });

  /// Create a Template from JSON data
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      path: json['path'],
      previewImageUrl: json['previewImageUrl'],
    );
  }

  /// Convert Template to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'path': path,
      'previewImageUrl': previewImageUrl,
    };
  }
}
