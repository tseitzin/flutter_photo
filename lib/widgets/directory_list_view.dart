import 'package:flutter/material.dart';
import 'package:flutter_photo/models/directory_stats.dart';

class DirectoryListView extends StatelessWidget {
  final List<DirectoryStats> directoryStats;
  final Function(DirectoryStats) onDirectoryTap;
  final String Function(String) getRelativePath;

  const DirectoryListView({
    super.key,
    required this.directoryStats,
    required this.onDirectoryTap,
    required this.getRelativePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.folder_copy, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Directories (${directoryStats.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 40, 37, 37),
                ),
              ),
              if (directoryStats.length > 5) ...[
                const SizedBox(width: 8),
                Text(
                  '(Showing first 5 of ${directoryStats.length})',
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
            itemCount: directoryStats.length,
            itemBuilder: (context, index) {
              if (index == 5) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text(
                    'Scroll to see ${directoryStats.length - 5} more directories...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              
              final stat = directoryStats[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.folder_open, color: Colors.blue, size: 16),
                    title: Text(
                      getRelativePath(stat.path),
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
                    onTap: () => onDirectoryTap(stat),
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
    );
  }
}