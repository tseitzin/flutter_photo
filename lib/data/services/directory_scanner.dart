import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter_photo/data/models/directory_stats.dart';
import 'package:flutter_photo/data/models/image_file_info.dart';

class DirectoryScanner {
  bool _isScanning = false;
  final List<String> _accessErrors = [];
  final Set<String> _unscannedDirectories = {};
  int _scannedFiles = 0;
  int _totalDirs = 1; // Initialize with 1 for root directory
  
  bool get isScanning => _isScanning;
  List<String> get accessErrors => List.unmodifiable(_accessErrors);
  Set<String> get unscannedDirectories => Set.unmodifiable(_unscannedDirectories);

  void reset() {
    _accessErrors.clear();
    _unscannedDirectories.clear();
    _scannedFiles = 0;
    _totalDirs = 1;
  }

  void cancel() {
    _isScanning = false;
  }

  bool _shouldSkipDirectory(String dirPath) {
    return path.split(dirPath).any((part) => part.startsWith('.'));
  }

  Future<(bool, String?)> _checkDirectoryAccess(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      
      if (!await dir.exists()) {
        return (false, 'Directory does not exist');
      }

      final testFile = File('${dir.path}${Platform.pathSeparator}.test_access');
      try {
        await testFile.create();
        await testFile.delete();
      } catch (e) {
        try {
          await dir.list().first;
          return (true, 'Read-only access');
        } catch (_) {
          return (false, 'No read or write permissions');
        }
      }

      await dir.list().first;
      return (true, null);
    } on PathAccessException catch (e) {
      return (false, 'Access denied: ${e.message}');
    } catch (e) {
      return (false, 'Error accessing directory: $e');
    }
  }

  String _getDetailedError(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    if (errorStr.contains('access') || errorStr.contains('permission')) {
      return 'Access denied';
    } else if (errorStr.contains('not found') || errorStr.contains('no such')) {
      return 'Directory not found';
    } else if (errorStr.contains('busy') || errorStr.contains('locked')) {
      return 'Directory is in use by another process';
    } else {
      return error.toString();
    }
  }

  Future<void> _scanDirectory(
    Directory directory,
    Map<String, int> directoryCounts,
    Map<String, List<String>> directoryErrors,
    Map<String, List<ImageFileInfo>> directoryImages,
    void Function(int scannedFiles, int totalDirs, int scannedDirs, int imagesFound) onProgress,
  ) async {
    if (_shouldSkipDirectory(directory.path)) {
      return;
    }

    try {
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        if (!_isScanning) return;

        if (entity is Directory) {
          if (_shouldSkipDirectory(entity.path)) {
            continue;
          }

          _totalDirs++; // Increment total directories counter
          onProgress(_scannedFiles, _totalDirs, directoryCounts.length, 0);

          await _scanDirectory(
            entity,
            directoryCounts,
            directoryErrors,
            directoryImages,
            onProgress,
          );
        } else if (entity is File) {
          if (_shouldSkipDirectory(path.dirname(entity.path))) {
            continue;
          }
          
          _scannedFiles++;
          onProgress(_scannedFiles, _totalDirs, directoryCounts.length, 0);
          
          String extension = path.extension(entity.path).toLowerCase();
          if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
            String dirPath = path.dirname(entity.path);
            directoryCounts[dirPath] = (directoryCounts[dirPath] ?? 0) + 1;
            
            if (!directoryImages.containsKey(dirPath)) {
              directoryImages[dirPath] = [];
            }

            final stat = await entity.stat();
            directoryImages[dirPath]!.add(ImageFileInfo(
              entity.path,
              path.basename(entity.path),
              stat.size,
              stat.modified,
            ));
            
            onProgress(_scannedFiles, _totalDirs, directoryCounts.length, 1);
          }
        }
      }
    } catch (e) {
      if (!_shouldSkipDirectory(directory.path)) {
        String errorMessage = e.toString();
        bool isAccessError = errorMessage.toLowerCase().contains('access') || 
                         errorMessage.toLowerCase().contains('permission');
        
        if (isAccessError) {
          _unscannedDirectories.add(directory.path);
        } else {
          _accessErrors.add('Error in ${directory.path}: ${_getDetailedError(e)}');
        }
      }
    }
  }

  Future<List<DirectoryStats>> scanDirectory(
    String directoryPath,
    void Function(int scannedFiles, int totalDirs, int scannedDirs, int imagesFound) onProgress,
  ) async {
    var (hasAccess, error) = await _checkDirectoryAccess(directoryPath);
    if (!hasAccess) {
      throw Exception('Cannot access directory: ${error ?? "Unknown error"}');
    }

    reset();
    _isScanning = true;

    final directory = Directory(directoryPath);
    Map<String, int> directoryCounts = {};
    Map<String, List<String>> directoryErrors = {};
    Map<String, List<ImageFileInfo>> directoryImages = {};
    
    await _scanDirectory(
      directory,
      directoryCounts,
      directoryErrors,
      directoryImages,
      onProgress,
    );

    if (!_isScanning) return [];

    List<DirectoryStats> stats = [];
    
    directoryCounts.forEach((dirPath, count) {
      stats.add(DirectoryStats(
        dirPath, 
        count,
        errors: directoryErrors[dirPath] ?? [],
        imageFiles: directoryImages[dirPath] ?? []
      ));
    });

    stats.sort((a, b) => a.path.compareTo(b.path));
    _isScanning = false;
    return stats;
  }
}