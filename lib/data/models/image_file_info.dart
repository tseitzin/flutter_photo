import 'package:flutter/foundation.dart';

@immutable
class ImageFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final Map<String, dynamic>? exifData;

  const ImageFileInfo(
    this.path, 
    this.name, 
    this.size, 
    this.modified, 
    {this.exifData}
  );

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'size': size,
      'modified_at': modified.toIso8601String(),
      'directory': path.substring(0, path.lastIndexOf('/')),
      'exif_data': exifData != null ? _serializeExif(exifData!) : null,
    };
  }

  static String _serializeExif(Map<String, dynamic> exif) {
    return exif.entries
        .map((e) => '${e.key}:${e.value.toString()}')
        .join('|');
  }

  static Map<String, dynamic>? _deserializeExif(String? data) {
    if (data == null) return null;
    
    final Map<String, dynamic> result = {};
    final entries = data.split('|');
    
    for (var entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    
    return result;
  }

  static ImageFileInfo fromMap(Map<String, dynamic> map) {
    return ImageFileInfo(
      map['path'] as String,
      map['name'] as String,
      map['size'] as int,
      DateTime.parse(map['modified_at'] as String),
      exifData: _deserializeExif(map['exif_data'] as String?),
    );
  }
}