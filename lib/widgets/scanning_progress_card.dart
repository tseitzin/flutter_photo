import 'package:flutter/material.dart';

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
          ),
        ),
      ),
    );
  }
}