import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class ImageFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;

  ImageFileInfo(this.path, this.name, this.size, this.modified);
}

class DirectoryStats {
  final String path;
  final int imageCount;
  final List<String> errors;
  final List<ImageFileInfo> imageFiles;
  final bool isAccessError;

  DirectoryStats(
    this.path, 
    this.imageCount, 
    {this.errors = const [], 
    this.imageFiles = const [],
    this.isAccessError = false}
  );
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
        _elapsedTime = _formatDuration(elapsed);
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
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_library, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Images in ${_getRelativePath(stats.path)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Text(
                '${stats.imageFiles.length} images found',
                style: const TextStyle(
                  color: Color.fromARGB(255, 49, 62, 62),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: stats.imageFiles.length,
                  itemBuilder: (context, index) {
                    final imageInfo = stats.imageFiles[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.image, size: 16, color: Color.fromARGB(255, 19, 91, 150)),
                      title: Text(
                        imageInfo.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        'Image Size: ${_formatFileSize(imageInfo.size)} • Date Created: ${_dateFormatter.format(imageInfo.modified)}',
                        style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 53, 51, 51)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 24, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Scan Errors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (_accessErrors.isNotEmpty) ...[
                const Text(
                  'Scanning Errors:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: _accessErrors.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _accessErrors[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (_unscannedDirectories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.folder_off, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Inaccessible Directories (${_unscannedDirectories.length}):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _unscannedDirectories.length,
                    itemBuilder: (context, index) {
                      final dir = _unscannedDirectories.elementAt(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getRelativePath(dir),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    dir,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
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
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Photo Analyzer',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            elevation: 2,
            actions: [
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextButton.icon(
                    onPressed: _cancelScan,
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('Stop Scan', style: TextStyle(color: Colors.red)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _exitApp,
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Exit'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_selectedDirectory == null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 28),
                              SizedBox(width: 16),
                              Text(
                                'Welcome to Photo Analyzer',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'This application helps you analyze and organize your photo collection by:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Scanning directories for image files'),
                                Text('• Counting images in each folder'),
                                Text('• Providing a detailed breakdown of your photo collection'),
                                Text('• Identifying inaccessible directories'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'How to use:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('1. Click "Select Directory" to choose a folder to analyze'),
                                Text('2. Wait for the scan to complete'),
                                Text('3. Review the analysis results'),
                                Text('4. Use the "Stop Scan" button if you need to cancel'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickDirectory(context),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select Directory'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Scanning $_selectedDirectory',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Files scanned: $_scannedFiles',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total directories scanned: $_totalDirs',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Directories with images: $_scannedDirs',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Images found: $_imagesFound',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Time elapsed: $_elapsedTime',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (_errorCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Errors encountered: $_errorCount',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (_selectedDirectory != null && !_isLoading) ...[
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.analytics, color: Colors.blue, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Analysis Results',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$_totalImages images in ${_directoryStats.length} directories',
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 128, 120, 120),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.folder, color: Color.fromARGB(255, 67, 62, 62), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedDirectory!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color.fromARGB(255, 67, 62, 62),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_errorCount > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: InkWell(
                                onTap: () => _showErrorsDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Errors: ${_accessErrors.length} scanning error${_accessErrors.length != 1 ? 's' : ''}, ${_unscannedDirectories.length} inaccessible director${_unscannedDirectories.length != 1 ? 'ies' : 'y'}',
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.red,
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.folder_copy, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Directories (${_directoryStats.length})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(255, 40, 37, 37),
                                        ),
                                      ),
                                      if (_directoryStats.length > 5) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(Showing first 5 of ${_directoryStats.length})',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _directoryStats.length,
                                    itemBuilder: (context, index) {
                                      if (index == 5) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                          child: Text(
                                            'Scroll to see ${_directoryStats.length - 5} more directories...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue.shade700,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        );
                                      }
                                      
                                      final stat = _directoryStats[index];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            dense: true,
                                            visualDensity: VisualDensity.compact,
                                            leading: const Icon(Icons.folder_open, color: Colors.blue, size: 16),
                                            title: Text(
                                              _getRelativePath(stat.path),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${stat.imageCount}',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            onTap: () => _showImagesDialog(context, stat),
                                          ),
                                          if (stat.errors.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 56, right: 16, bottom: 4),
                                              child: Text(
                                                stat.errors.join('\n'),
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}