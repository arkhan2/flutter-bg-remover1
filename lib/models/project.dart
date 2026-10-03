import 'package:uuid/uuid.dart';
import 'edited_image.dart';

class Project {
  final String id;
  final String name;
  final String? originalImagePath;
  final String? processedImagePath;
  final String? displayImagePath;
  final String? thumbnailPath;
  final BackgroundType backgroundType;
  final int? solidColorValue;
  final List<int>? gradientColorValues;
  final double? blurRadius;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    String? id,
    required this.name,
    this.originalImagePath,
    this.processedImagePath,
    this.displayImagePath,
    this.thumbnailPath,
    this.backgroundType = BackgroundType.transparent,
    this.solidColorValue,
    this.gradientColorValues,
    this.blurRadius,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Project copyWith({
    String? id,
    String? name,
    String? originalImagePath,
    String? processedImagePath,
    String? displayImagePath,
    String? thumbnailPath,
    BackgroundType? backgroundType,
    int? solidColorValue,
    List<int>? gradientColorValues,
    double? blurRadius,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      displayImagePath: displayImagePath ?? this.displayImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      backgroundType: backgroundType ?? this.backgroundType,
      solidColorValue: solidColorValue ?? this.solidColorValue,
      gradientColorValues: gradientColorValues ?? this.gradientColorValues,
      blurRadius: blurRadius ?? this.blurRadius,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String? get previewImagePath =>
      thumbnailPath ?? displayImagePath ?? processedImagePath ?? originalImagePath;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalImagePath': originalImagePath,
      'processedImagePath': processedImagePath,
      'displayImagePath': displayImagePath,
      'thumbnailPath': thumbnailPath,
      'backgroundType': backgroundType.index,
      'solidColorValue': solidColorValue,
      'gradientColorValues': gradientColorValues,
      'blurRadius': blurRadius,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      originalImagePath: json['originalImagePath'] as String?,
      processedImagePath: json['processedImagePath'] as String?,
      displayImagePath: json['displayImagePath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      backgroundType: BackgroundType.values[json['backgroundType'] as int? ?? 0],
      solidColorValue: json['solidColorValue'] as int?,
      gradientColorValues: (json['gradientColorValues'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      blurRadius: json['blurRadius'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
