import 'package:flutter/material.dart';

class ErrorsDialog extends StatelessWidget {
  final List<String> accessErrors;
  final Set<String> unscannedDirectories;
  final String Function(String) getRelativePath;

  const ErrorsDialog({
    super.key,
    required this.accessErrors,
    required this.unscannedDirectories,
    required this.getRelativePath,
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
                const Icon(Icons.error_outline, size: 24, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Scan Errors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (accessErrors.isNotEmpty) ...[
              const Text(
                'Scanning Errors:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: accessErrors.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              accessErrors[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (unscannedDirectories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.folder_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Inaccessible Directories (${unscannedDirectories.length}):',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: unscannedDirectories.length,
                  itemBuilder: (context, index) {
                    final dir = unscannedDirectories.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getRelativePath(dir),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  dir,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}