import 'package:flutter/material.dart';
import 'package:flutter_photo/data/models/image_file_info.dart';
import 'package:flutter_photo/utils/format_utils.dart';
import 'package:intl/intl.dart';

class ImageDetailsDialog extends StatelessWidget {
  final ImageFileInfo imageInfo;
  final DateFormat dateFormatter;

  const ImageDetailsDialog({
    super.key,
    required this.imageInfo,
    required this.dateFormatter,
  });

  Widget _buildExifSection() {
    if (imageInfo.exifData == null || imageInfo.exifData!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No EXIF data available',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'EXIF Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imageInfo.exifData!.length,
          itemBuilder: (context, index) {
            final entry = imageInfo.exifData!.entries.elementAt(index);
            // Format the tag name for better readability
            String tagName = entry.key
                .split('.')
                .last
                .replaceAll(RegExp(r'(?=[A-Z])', caseSensitive: true), ' ')
                .trim();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      tagName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Text(': '),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image Details: ${imageInfo.name}',
                    style: const TextStyle(
                      fontSize: 18,
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Path: ${imageInfo.path}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${formatFileSize(imageInfo.size)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modified: ${dateFormatter.format(imageInfo.modified)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    _buildExifSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}