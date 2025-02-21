import 'package:flutter/material.dart';

class ScanningProgress extends StatelessWidget {
  final int scannedFiles;
  final int totalDirs;
  final int scannedDirs;
  final int imagesFound;
  final String elapsedTime;
  final int errorCount;

  const ScanningProgress({
    super.key,
    required this.scannedFiles,
    required this.totalDirs,
    required this.scannedDirs,
    required this.imagesFound,
    required this.elapsedTime,
    required this.errorCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Files scanned: $scannedFiles',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Total directories scanned: $totalDirs',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Directories with images: $scannedDirs',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Images found: $imagesFound',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Time elapsed: $elapsedTime',
          style: const TextStyle(color: Colors.grey),
        ),
        if (errorCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Errors encountered: $errorCount',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}