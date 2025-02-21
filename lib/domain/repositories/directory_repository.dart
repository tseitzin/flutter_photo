import 'dart:io';
import '../../data/models/directory_stats.dart';

/// Repository interface for handling directory scanning operations
abstract class DirectoryRepository {
  /// List of directories that couldn't be accessed during scanning
  List<String> get accessErrors;

  /// List of directories that weren't scanned
  List<String> get unscannedDirectories;

  /// Scans a directory and returns statistics about images found
  /// 
  /// Parameters:
  /// - path: The directory path to scan
  /// - onProgress: Callback function to report scanning progress
  Future<List<DirectoryStats>> scanDirectory(
    String path,
    void Function(
      int scannedFiles,
      int totalDirs,
      int scannedDirs,
      int imagesFound,
    ) onProgress,
  );

  /// Cancels the current scanning operation
  void cancelScan();
}

/// Implementation of the DirectoryRepository interface
class DirectoryRepositoryImpl implements DirectoryRepository {
  final List<String> _accessErrors = [];
  final List<String> _unscannedDirectories = [];
  bool _isCancelled = false;

  @override
  List<String> get accessErrors => List.unmodifiable(_accessErrors);

  @override
  List<String> get unscannedDirectories => List.unmodifiable(_unscannedDirectories);

  @override
  Future<List<DirectoryStats>> scanDirectory(
    String path,
    void Function(int scannedFiles, int totalDirs, int scannedDirs, int imagesFound) onProgress,
  ) async {
    _isCancelled = false;
    _accessErrors.clear();
    _unscannedDirectories.clear();

    try {
      final directory = Directory(path);
      if (!directory.existsSync()) {
        throw DirectoryNotFoundException('Directory not found: $path');
      }

      final stats = <DirectoryStats>[];
      int scannedFiles = 0;
      int scannedDirs = 0;
      int totalDirs = 0;
      int imagesFound = 0;

      // First pass: count total directories
      await _countDirectories(directory, (count) => totalDirs = count);

      // Second pass: scan files
      await for (final entity in directory.list(recursive: true)) {
        if (_isCancelled) break;

        if (entity is Directory) {
          scannedDirs++;
        } else if (entity is File) {
          scannedFiles++;
          final extension = entity.path.split('.').last.toLowerCase();
          
          if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
            imagesFound++;
            final dirPath = entity.parent.path;
            final dirStat = stats.firstWhere(
              (stat) => stat.path == dirPath,
              orElse: () {
                final newStat = DirectoryStats(dirPath, 0);
                stats.add(newStat);
                return newStat;
              },
            );
            dirStat.addImage(entity);
          }
        }

        onProgress(scannedFiles, totalDirs, scannedDirs, imagesFound);
      }

      return stats;
    } catch (e) {
      _accessErrors.add('Error scanning directory: ${e.toString()}');
      return [];
    }
  }

  Future<void> _countDirectories(Directory directory, void Function(int count) onCount) async {
    int count = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is Directory) count++;
      }
      onCount(count);
    } catch (e) {
      _unscannedDirectories.add(directory.path);
    }
  }

  @override
  void cancelScan() {
    _isCancelled = true;
  }
}

/// Exception thrown when a directory is not found
class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);

  @override
  String toString() => message;
}