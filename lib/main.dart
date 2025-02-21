import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:flutter_photo/models/directory_stats.dart';
import 'package:flutter_photo/models/image_file_info.dart';
import 'package:flutter_photo/utils/format_utils.dart';
import 'package:flutter_photo/widgets/dialogs/images_dialog.dart';
import 'package:flutter_photo/widgets/dialogs/errors_dialog.dart';
import 'package:flutter_photo/widgets/photo_analyzer_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _selectedDirectory;
  List<DirectoryStats> _directoryStats = [];
  int _totalImages = 0;
  bool _isLoading = false;
  int _scannedFiles = 0;
  int _scannedDirs = 0;
  int _imagesFound = 0;
  int _totalDirs = 0;
  int _errorCount = 0;
  final List<String> _accessErrors = [];
  final Set<String> _unscannedDirectories = {};
  
  DateTime? _scanStartTime;
  Timer? _updateTimer;
  String _elapsedTime = "0:00";

  final DateFormat _dateFormatter = DateFormat('MMM d, y HH:mm');

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }


  void _startTimer() {
    _scanStartTime = DateTime.now();
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isLoading) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(_scanStartTime!);
      
      setState(() {
        _elapsedTime = formatDuration(elapsed);
      });
    });
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

  bool _shouldSkipDirectory(String dirPath) {
    return path.split(dirPath).any((part) => part.startsWith('.'));
  }

  Future<void> _scanDirectory(Directory directory, Map<String, int> directoryCounts, Map<String, List<String>> directoryErrors, Map<String, List<ImageFileInfo>> directoryImages) async {
    if (_shouldSkipDirectory(directory.path)) {
      return;
    }

    try {
      setState(() {
        _totalDirs++;
      });

      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        if (!_isLoading) return;

        if (entity is Directory) {
          if (_shouldSkipDirectory(entity.path)) {
            continue;
          }

          await _scanDirectory(entity, directoryCounts, directoryErrors, directoryImages);
        } else if (entity is File) {
          if (_shouldSkipDirectory(path.dirname(entity.path))) {
            continue;
          }

          setState(() {
            _scannedFiles++;
          });
          
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
              stat.modified
            ));
            
            setState(() {
              _scannedDirs = directoryCounts.length;
              _imagesFound++;
            });
          }
        }
      }
    } catch (e) {
      if (!_shouldSkipDirectory(directory.path)) {
        String errorMessage = e.toString();
        bool isAccessError = errorMessage.toLowerCase().contains('access') || 
                          errorMessage.toLowerCase().contains('permission');
        
        if (isAccessError) {
          setState(() {
            _unscannedDirectories.add(directory.path);
          });
        } else {
          _accessErrors.add('Error in ${directory.path}: ${_getDetailedError(e)}');
        }
        
        setState(() {
          _errorCount++;
        });
      }
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

  Future<void> _pickDirectory(BuildContext context) async {
    try {
      String? directoryPath = await getDirectoryPath();
      
      if (directoryPath != null) {
        var (hasAccess, error) = await _checkDirectoryAccess(directoryPath);
        if (!hasAccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot access directory: ${error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _pickDirectory(context),
                ),
              )
            );
          }
          return;
        }

        setState(() {
          _isLoading = true;
          _scannedFiles = 0;
          _scannedDirs = 0;
          _imagesFound = 0;
          _totalDirs = 0;
          _errorCount = 0;
          _selectedDirectory = directoryPath;
          _directoryStats = [];
          _totalImages = 0;
          _accessErrors.clear();
          _unscannedDirectories.clear();
          _elapsedTime = "0:00";
        });

        _startTimer();

        final directory = Directory(directoryPath);
        Map<String, int> directoryCounts = {};
        Map<String, List<String>> directoryErrors = {};
        Map<String, List<ImageFileInfo>> directoryImages = {};
        
        await _scanDirectory(directory, directoryCounts, directoryErrors, directoryImages);

        _updateTimer?.cancel();

        if (!_isLoading) return;

        List<DirectoryStats> stats = [];
        int total = 0;
        
        directoryCounts.forEach((dirPath, count) {
          stats.add(DirectoryStats(
            dirPath, 
            count,
            errors: directoryErrors[dirPath] ?? [],
            imageFiles: directoryImages[dirPath] ?? []
          ));
          total += count;
        });

        stats.sort((a, b) => a.path.compareTo(b.path));

        setState(() {
          _directoryStats = stats;
          _totalImages = total;
          _isLoading = false;
        });

        if (_totalImages == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No images found in the selected directory'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              )
            );
          }
        }
      }
    } catch (e) {
      _updateTimer?.cancel();
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning directory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _pickDirectory(context),
            ),
          )
        );
      }
    }
  }

  void _exitApp() {
    exit(0);
  }

  void _cancelScan() {
    _updateTimer?.cancel();
    setState(() {
      _isLoading = false;
    });
  }

  String _getRelativePath(String fullPath) {
    if (_selectedDirectory == null) return fullPath;
    
    String normalizedFullPath = path.normalize(fullPath);
    String normalizedSelectedDir = path.normalize(_selectedDirectory!);
    
    if (normalizedFullPath == normalizedSelectedDir) {
      return path.basename(normalizedFullPath);
    }
    
    if (normalizedFullPath.startsWith(normalizedSelectedDir)) {
      String relativePath = normalizedFullPath.substring(
        normalizedSelectedDir.length + (normalizedSelectedDir.endsWith(path.separator) ? 0 : 1)
      );
      return relativePath;
    }
    
    return fullPath;
  }

  void _showImagesDialog(BuildContext context, DirectoryStats stats) {
    showDialog(
      context: context,
      builder: (context) => ImagesDialog(
        stats: stats,
        relativePath: _getRelativePath(stats.path),
        dateFormatter: _dateFormatter,
      ),
    );
  }

  void _showErrorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ErrorsDialog(
        accessErrors: _accessErrors,
        unscannedDirectories: _unscannedDirectories,
        getRelativePath: _getRelativePath,
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ScaffoldMessenger(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Builder(
        builder: (context) => PhotoAnalyzerLayout(
          selectedDirectory: _selectedDirectory,
          isLoading: _isLoading,
          directoryStats: _directoryStats,
          totalImages: _totalImages,
          scannedFiles: _scannedFiles,
          totalDirs: _totalDirs,
          scannedDirs: _scannedDirs,
          imagesFound: _imagesFound,
          elapsedTime: _elapsedTime,
          errorCount: _errorCount,
          accessErrorsCount: _accessErrors.length,
          unscannedDirectoriesCount: _unscannedDirectories.length,
          onCancelScan: _cancelScan,
          onExit: _exitApp,
          onSelectDirectory: () => _pickDirectory(context),
          onDirectoryTap: (stats) => _showImagesDialog(context, stats),
          onErrorsTap: () => _showErrorsDialog(context),
          getRelativePath: _getRelativePath,
        ),
      ),
    );
  }
}