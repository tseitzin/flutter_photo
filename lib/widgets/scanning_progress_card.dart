import 'package:flutter/material.dart';
import 'package:flutter_photo/widgets/scanning_progress.dart';

class ScanningProgressCard extends StatelessWidget {
  final String selectedDirectory;
  final int scannedFiles;
  final int totalDirs;
  final int scannedDirs;
  final int imagesFound;
  final String elapsedTime;
  final int errorCount;

  const ScanningProgressCard({
    super.key,
    required this.selectedDirectory,
    required this.scannedFiles,
    required this.totalDirs,
    required this.scannedDirs,
    required this.imagesFound,
    required this.elapsedTime,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      'Scanning $selectedDirectory',
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
              ScanningProgress(
                scannedFiles: scannedFiles,
                totalDirs: totalDirs,
                scannedDirs: scannedDirs,
                imagesFound: imagesFound,
                elapsedTime: elapsedTime,
                errorCount: errorCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}