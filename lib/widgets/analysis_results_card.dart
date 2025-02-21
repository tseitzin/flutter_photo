import 'package:flutter/material.dart';
import 'package:flutter_photo/models/directory_stats.dart';
import 'package:flutter_photo/widgets/directory_list_view.dart';
import 'package:flutter_photo/widgets/error_banner.dart';

class AnalysisResultsCard extends StatelessWidget {
  final String selectedDirectory;
  final List<DirectoryStats> directoryStats;
  final int totalImages;
  final Function(DirectoryStats) onDirectoryTap;
  final Function() onErrorsTap;
  final String Function(String) getRelativePath;
  final int accessErrorsCount;
  final int unscannedDirectoriesCount;

  const AnalysisResultsCard({
    super.key,
    required this.selectedDirectory,
    required this.directoryStats,
    required this.totalImages,
    required this.onDirectoryTap,
    required this.onErrorsTap,
    required this.getRelativePath,
    required this.accessErrorsCount,
    required this.unscannedDirectoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        '$totalImages images in ${directoryStats.length} directories',
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
                          selectedDirectory,
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
            if (accessErrorsCount > 0 || unscannedDirectoriesCount > 0)
              ErrorBanner(
                accessErrorsCount: accessErrorsCount,
                unscannedDirectoriesCount: unscannedDirectoriesCount,
                onTap: onErrorsTap,
              ),
            Expanded(
              child: DirectoryListView(
                directoryStats: directoryStats,
                onDirectoryTap: onDirectoryTap,
                getRelativePath: getRelativePath,
              ),
            ),
          ],
        ),
      ),
    );
  }
}