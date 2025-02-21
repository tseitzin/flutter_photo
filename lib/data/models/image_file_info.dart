import 'package:flutter/foundation.dart';

@immutable
class ImageFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;

  const ImageFileInfo(this.path, this.name, this.size, this.modified);
}