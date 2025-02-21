import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:flutter_photo/data/models/directory_stats.dart';
import 'package:flutter_photo/utils/format_utils.dart';
import 'package:flutter_photo/presentation/widgets/dialogs/images_dialog.dart';
import 'package:flutter_photo/presentation/widgets/dialogs/errors_dialog.dart';
import 'package:flutter_photo/presentation/widgets/photo_analyzer_layout.dart';
import 'package:flutter_photo/data/services/directory_scanner.dart';

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
  final DirectoryScanner _scanner = DirectoryScanner();
  String? _selectedDirectory;
  List<DirectoryStats> _directoryStats = [];
  int _totalImages = 0;
  bool _isLoading = false;
  int _scannedFiles = 0;
  int _scannedDirs = 0;
  int _imagesFound = 0;
  int _totalDirs = 0;
  int _errorCount = 0;
  
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

  void _cancelScan() {
    _updateTimer?.cancel();
    _scanner.cancel();
    setState(() {
      _isLoading = false;
    });
  }

  void _exitApp() {
    exit(0);
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
        accessErrors: _scanner.accessErrors,
        unscannedDirectories: _scanner.unscannedDirectories,
        getRelativePath: _getRelativePath,
      ),
    );
  }

  Future<void> _pickDirectory(BuildContext context) async {
    try {
      String? directoryPath = await getDirectoryPath();
      
      if (directoryPath != null) {
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
          _elapsedTime = "0:00";
        });

        _startTimer();

        try {
          final stats = await _scanner.scanDirectory(
            directoryPath,
            (scannedFiles, totalDirs, scannedDirs, imagesFound) {
              setState(() {
                _scannedFiles = scannedFiles;
                _totalDirs = totalDirs;
                _scannedDirs = scannedDirs;
                _imagesFound += imagesFound;
                _errorCount = _scanner.accessErrors.length + _scanner.unscannedDirectories.length;
              });
            },
          );

          _updateTimer?.cancel();

          if (!_isLoading) return;

          int total = 0;
          for (var stat in stats) {
            total += stat.imageCount;
          }

          setState(() {
            _directoryStats = stats;
            _totalImages = total;
            _isLoading = false;
          });

          if (_totalImages == 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No images found in the selected directory'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              )
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot access directory: $e'),
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
          setState(() {
            _isLoading = false;
          });
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
          accessErrorsCount: _scanner.accessErrors.length,
          unscannedDirectoriesCount: _scanner.unscannedDirectories.length,
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