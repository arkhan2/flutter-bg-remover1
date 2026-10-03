import 'dart:typed_data';
import 'package:flutter/material.dart';

enum BackgroundType {
  transparent,
  solid,
  gradient,
  blur,
}

class EditedImage {
  final Uint8List? originalBytes;
  final Uint8List? processedBytes;
  final Uint8List? displayBytes;
  final BackgroundType backgroundType;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final double? blurRadius;
  final bool isProcessing;
  final String? errorMessage;

  const EditedImage({
    this.originalBytes,
    this.processedBytes,
    this.displayBytes,
    this.backgroundType = BackgroundType.transparent,
    this.solidColor,
    this.gradientColors,
    this.blurRadius,
    this.isProcessing = false,
    this.errorMessage,
  });

  EditedImage copyWith({
    Uint8List? originalBytes,
    Uint8List? processedBytes,
    Uint8List? displayBytes,
    BackgroundType? backgroundType,
    Color? solidColor,
    List<Color>? gradientColors,
    double? blurRadius,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return EditedImage(
      originalBytes: originalBytes ?? this.originalBytes,
      processedBytes: processedBytes ?? this.processedBytes,
      displayBytes: displayBytes ?? this.displayBytes,
      backgroundType: backgroundType ?? this.backgroundType,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      blurRadius: blurRadius ?? this.blurRadius,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }

  bool get hasOriginal => originalBytes != null;
  bool get hasProcessed => processedBytes != null;
  bool get hasDisplay => displayBytes != null;

  Map<String, dynamic> toJson() {
    return {
      'backgroundType': backgroundType.index,
      'solidColor': solidColor?.value,
      'gradientColors': gradientColors?.map((c) => c.value).toList(),
      'blurRadius': blurRadius,
    };
  }

  factory EditedImage.fromJson(Map<String, dynamic> json) {
    return EditedImage(
      backgroundType: BackgroundType.values[json['backgroundType'] as int? ?? 0],
      solidColor: json['solidColor'] != null ? Color(json['solidColor'] as int) : null,
      gradientColors: (json['gradientColors'] as List<dynamic>?)
          ?.map((c) => Color(c as int))
          .toList(),
      blurRadius: json['blurRadius'] as double?,
    );
  }
}
