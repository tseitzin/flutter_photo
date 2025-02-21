import 'package:flutter/material.dart';
import 'package:flutter_photo/data/models/directory_stats.dart';
import 'package:flutter_photo/utils/format_utils.dart';
import 'package:intl/intl.dart';

class ImagesDialog extends StatelessWidget {
  final DirectoryStats stats;
  final String relativePath;
  final DateFormat dateFormatter;

  const ImagesDialog({
    super.key,
    required this.stats,
    required this.relativePath,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    'Images in $relativePath',
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
                      'Image Size: ${formatFileSize(imageInfo.size)} • Date Created: ${dateFormatter.format(imageInfo.modified)}',
                      style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 53, 51, 51)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}