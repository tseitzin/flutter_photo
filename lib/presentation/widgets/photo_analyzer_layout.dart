import 'package:flutter/material.dart';
import 'package:flutter_photo/data/models/directory_stats.dart';
import 'package:flutter_photo/presentation/widgets/welcome_card.dart';
import 'package:flutter_photo/presentation/widgets/scanning_progress_card.dart';
import 'package:flutter_photo/presentation/widgets/analysis_results_card.dart';
import 'package:flutter_photo/presentation/widgets/photo_analyzer_app_bar.dart';
import 'package:flutter_photo/presentation/widgets/select_directory_button.dart';
import 'package:flutter_photo/presentation/screens/database_viewer_screen.dart';

class PhotoAnalyzerLayout extends StatelessWidget {
  final String? selectedDirectory;
  final bool isLoading;
  final List<DirectoryStats> directoryStats;
  final int totalImages;
  final int scannedFiles;
  final int totalDirs;
  final int scannedDirs;
  final int imagesFound;
  final String elapsedTime;
  final int errorCount;
  final int accessErrorsCount;
  final int unscannedDirectoriesCount;
  final VoidCallback onCancelScan;
  final VoidCallback onExit;
  final VoidCallback onSelectDirectory;
  final Function(DirectoryStats) onDirectoryTap;
  final VoidCallback onErrorsTap;
  final String Function(String) getRelativePath;

  const PhotoAnalyzerLayout({
    super.key,
    required this.selectedDirectory,
    required this.isLoading,
    required this.directoryStats,
    required this.totalImages,
    required this.scannedFiles,
    required this.totalDirs,
    required this.scannedDirs,
    required this.imagesFound,
    required this.elapsedTime,
    required this.errorCount,
    required this.accessErrorsCount,
    required this.unscannedDirectoriesCount,
    required this.onCancelScan,
    required this.onExit,
    required this.onSelectDirectory,
    required this.onDirectoryTap,
    required this.onErrorsTap,
    required this.getRelativePath,
  });

  void _showDatabaseViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DatabaseViewerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PhotoAnalyzerAppBar(
        isLoading: isLoading,
        onCancelScan: onCancelScan,
        onExit: onExit,
        onViewDatabase: () => _showDatabaseViewer(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (selectedDirectory == null && !isLoading)
            const WelcomeCard(),
          SelectDirectoryButton(
            isLoading: isLoading,
            onSelectDirectory: onSelectDirectory,
          ),
          if (isLoading && selectedDirectory != null)
            ScanningProgressCard(
              selectedDirectory: selectedDirectory!,
              scannedFiles: scannedFiles,
              totalDirs: totalDirs,
              scannedDirs: scannedDirs,
              imagesFound: imagesFound,
              elapsedTime: elapsedTime,
              errorCount: errorCount,
            ),
          if (selectedDirectory != null && !isLoading)
            Expanded(
              child: AnalysisResultsCard(
                selectedDirectory: selectedDirectory!,
                directoryStats: directoryStats,
                totalImages: totalImages,
                onDirectoryTap: onDirectoryTap,
                onErrorsTap: onErrorsTap,
                getRelativePath: getRelativePath,
                accessErrorsCount: accessErrorsCount,
                unscannedDirectoriesCount: unscannedDirectoriesCount,
              ),
            ),
        ],
      ),
    );
  }
}