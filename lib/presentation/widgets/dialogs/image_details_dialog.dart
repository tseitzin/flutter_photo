import 'dart:io';
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

  String? _getCreationDate() {
    if (imageInfo.exifData == null) return null;

    // Try different EXIF tags for creation date
    final dateKeys = [
      'EXIF.DateTimeOriginal',
      'EXIF.DateTimeDigitized',
      'Image.DateTime',
    ];

    for (var key in dateKeys) {
      final value = imageInfo.exifData![key];
      if (value != null) {
        try {
          // EXIF dates are typically in format "YYYY:MM:DD HH:MM:SS"
          final parts = value.toString().split(' ');
          if (parts.length == 2) {
            final date = parts[0].replaceAll(':', '-');
            final time = parts[1];
            final dateTime = DateTime.parse('$date $time');
            return dateFormatter.format(dateTime);
          }
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final creationDate = _getCreationDate();
    final screenSize = MediaQuery.of(context).size;
    final maxImageSize = Size(
      screenSize.width * 0.4,
      screenSize.height * 0.4,
    );

    return Dialog(
      child: Container(
        width: screenSize.width * 0.6,
        height: screenSize.height * 0.8,
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
                    imageInfo.name,
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
                    if (creationDate != null)
                      Text(
                        'Created: $creationDate',
                        style: const TextStyle(fontSize: 12),
                      )
                    else
                      Text(
                        'Modified: ${dateFormatter.format(imageInfo.modified)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: maxImageSize.width,
                          maxHeight: maxImageSize.height,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imageInfo.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
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