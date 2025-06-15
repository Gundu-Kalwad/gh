import 'package:flutter/material.dart';

/// Model class for AI resources
class AIResource {
  final String name;
  final String description;
  final String url;
  final IconData icon;
  final Color color;
  final bool needsExternalBrowser;

  const AIResource({
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
    required this.needsExternalBrowser,
  });
}
