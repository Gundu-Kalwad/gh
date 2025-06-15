import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class to hold repository info for a project
class RepositoryInfo {
  final String owner;
  final String repoName;
  final DateTime lastUploadTimestamp;

  RepositoryInfo({
    required this.owner,
    required this.repoName,
    required this.lastUploadTimestamp,
  });

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repoName': repoName,
        'lastUploadTimestamp': lastUploadTimestamp.toIso8601String(),
      };

  factory RepositoryInfo.fromJson(Map<String, dynamic> json) => RepositoryInfo(
        owner: json['owner'],
        repoName: json['repoName'],
        lastUploadTimestamp: DateTime.parse(json['lastUploadTimestamp']),
      );
}

/// Handles storing and retrieving repository info for each project
class RepositoryStorage {
  static const String _repoMapKey = 'project_repo_info_map';

  /// Save repository info for a project path
  static Future<void> saveRepositoryInfo(String projectPath, RepositoryInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadRepoMap(prefs);
    map[projectPath] = jsonEncode(info.toJson());
    await prefs.setString(_repoMapKey, jsonEncode(map));
  }

  /// Get repository info for a project path
  static Future<RepositoryInfo?> getRepositoryInfo(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadRepoMap(prefs);
    final jsonStr = map[projectPath];
    if (jsonStr == null) return null;
    return RepositoryInfo.fromJson(jsonDecode(jsonStr));
  }

  /// Remove repository info for a project path
  static Future<void> removeRepositoryInfo(String projectPath) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _loadRepoMap(prefs);
    map.remove(projectPath);
    await prefs.setString(_repoMapKey, jsonEncode(map));
  }

  /// Internal: load the full map from prefs
  static Future<Map<String, dynamic>> _loadRepoMap(SharedPreferences prefs) async {
    final jsonStr = prefs.getString(_repoMapKey);
    if (jsonStr == null) return {};
    return Map<String, dynamic>.from(jsonDecode(jsonStr));
  }
}
