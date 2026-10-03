import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';

class StorageService {
  static const _uuid = Uuid();
  static final Map<String, Uint8List> _images = {};
  static final Map<String, Project> _projects = {};

  static Future<String> saveImage(Uint8List imageBytes, {String? filename}) async {
    final name = filename ?? '${_uuid.v4()}.png';
    _images[name] = imageBytes;
    return name;
  }

  static Future<Uint8List?> loadImage(String path) async {
    return _images[path];
  }

  static Future<void> deleteImage(String path) async {
    _images.remove(path);
  }

  static Future<Project> saveProject(Project project) async {
    _projects[project.id] = project;
    return project;
  }

  static Future<List<Project>> loadProjects() async {
    final projects = _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  static Future<Project?> loadProject(String id) async {
    return _projects[id];
  }

  static Future<void> deleteProject(String id) async {
    final project = _projects.remove(id);
    if (project == null) return;

    for (final path in [
      project.originalImagePath,
      project.processedImagePath,
      project.displayImagePath,
      project.thumbnailPath,
    ]) {
      if (path != null) {
        await deleteImage(path);
      }
    }
  }

  static Future<String> exportToFile(Uint8List imageBytes, String filename) async {
    _images[filename] = imageBytes;
    return filename;
  }

  static void clearAll() {
    _images.clear();
    _projects.clear();
  }
}
