import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/storage_service.dart';
import '../models/project.dart';

class GalleryState {
  final List<Project> projects;
  final bool isLoading;
  final String? errorMessage;

  const GalleryState({
    this.projects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  GalleryState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GalleryState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isEmpty => projects.isEmpty;
  int get count => projects.length;
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  GalleryNotifier() : super(const GalleryState());

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final projects = await StorageService.loadProjects();
      state = state.copyWith(
        projects: projects,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load projects: $e',
      );
    }
  }

  Future<void> saveProject(Project project) async {
    try {
      final savedProject = await StorageService.saveProject(project);
      final updatedProjects = [...state.projects];
      final existingIndex = updatedProjects.indexWhere((p) => p.id == savedProject.id);
      
      if (existingIndex >= 0) {
        updatedProjects[existingIndex] = savedProject;
      } else {
        updatedProjects.insert(0, savedProject);
      }
      
      state = state.copyWith(projects: updatedProjects);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await StorageService.deleteProject(id);
      final updatedProjects = state.projects.where((p) => p.id != id).toList();
      state = state.copyWith(projects: updatedProjects);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final galleryProvider = StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  return GalleryNotifier();
});
