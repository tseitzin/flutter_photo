import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_photo/presentation/widgets/photo_analyzer_layout.dart';
import 'package:flutter_photo/presentation/providers/photo_analyzer_provider.dart';

class PhotoAnalyzerScreen extends ConsumerWidget {
  const PhotoAnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoAnalyzerProvider);
    final notifier = ref.read(photoAnalyzerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Analyzer'),
        actions: [
          if (state.isLoading)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Cancel Scan',
              onPressed: notifier.cancelScan,
            ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Select Directory',
            onPressed: state.isLoading ? null : () => notifier.pickDirectory(context),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Exit',
            onPressed: notifier.exitApp,
          ),
        ],
      ),
      body: PhotoAnalyzerLayout(
        selectedDirectory: state.selectedDirectory,
        isLoading: state.isLoading,
        directoryStats: state.directoryStats,
        totalImages: state.totalImages,
        scannedFiles: state.scannedFiles,
        scannedDirs: state.scannedDirs,
        imagesFound: state.imagesFound,
        totalDirs: state.totalDirs,
        errorCount: state.errorCount,
        elapsedTime: state.elapsedTime.toString(),
        onDirectoryTap: (stats) => notifier.showImagesDialog(context, stats),
        onErrorsTap: () {
          if (state.errorCount > 0) {
            notifier.showErrorsDialog(context);
          }
        },
        accessErrorsCount: 0,
        unscannedDirectoriesCount: 0,
        onCancelScan: notifier.cancelScan,
        onExit: notifier.exitApp,
        onSelectDirectory: () => notifier.pickDirectory(context),
        getRelativePath: (path) => path.replaceFirst('${state.selectedDirectory}/', ''),
      ),
    );
  }
}