import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';

class StorageService {
  static const _projectsFolder = 'projects';
  static const _imagesFolder = 'images';
  static final _uuid = const Uuid();

  static Future<Directory> _getProjectsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${appDir.path}/$_projectsFolder');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  static Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$_imagesFolder');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  static Future<String> saveImage(Uint8List imageBytes, {String? filename}) async {
    final imagesDir = await _getImagesDirectory();
    final name = filename ?? '${_uuid.v4()}.png';
    final file = File('${imagesDir.path}/$name');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  static Future<Uint8List?> loadImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<Project> saveProject(Project project) async {
    final projectsDir = await _getProjectsDirectory();
    final projectFile = File('${projectsDir.path}/${project.id}.json');
    final json = project.toJson();
    await projectFile.writeAsString(jsonEncode(json));
    return project;
  }

  static Future<List<Project>> loadProjects() async {
    try {
      final projectsDir = await _getProjectsDirectory();
      final files = await projectsDir.list().toList();
      final projects = <Project>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            projects.add(Project.fromJson(json));
          } catch (e) {
            // Skip corrupted files
          }
        }
      }

      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return projects;
    } catch (e) {
      return [];
    }
  }

  static Future<Project?> loadProject(String id) async {
    try {
      final projectsDir = await _getProjectsDirectory();
      final projectFile = File('${projectsDir.path}/$id.json');
      
      if (await projectFile.exists()) {
        final content = await projectFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return Project.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> deleteProject(String id) async {
    try {
      final projectsDir = await _getProjectsDirectory();
      final projectFile = File('${projectsDir.path}/$id.json');
      
      if (await projectFile.exists()) {
        final content = await projectFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final project = Project.fromJson(json);
        
        if (project.originalImagePath != null) {
          await deleteImage(project.originalImagePath!);
        }
        if (project.processedImagePath != null) {
          await deleteImage(project.processedImagePath!);
        }
        
        await projectFile.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  static Future<String> exportToFile(Uint8List imageBytes, String filename) async {
    final exportDir = await getExportDirectory();
    final file = File('$exportDir/$filename');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }
}
