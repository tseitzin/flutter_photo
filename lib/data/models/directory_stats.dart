import 'package:flutter/foundation.dart';
import 'package:flutter_photo/data/models/image_file_info.dart';

@immutable
class DirectoryStats {
  final String path;
  final int imageCount;
  final List<String> errors;
  final List<ImageFileInfo> imageFiles;
  final bool isAccessError;

  const DirectoryStats(
    this.path, 
    this.imageCount, 
    {this.errors = const [], 
    this.imageFiles = const [],
    this.isAccessError = false}
  );
}