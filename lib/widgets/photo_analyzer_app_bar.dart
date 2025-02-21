import 'package:flutter/material.dart';

class PhotoAnalyzerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final VoidCallback onCancelScan;
  final VoidCallback onExit;

  const PhotoAnalyzerAppBar({
    super.key,
    required this.isLoading,
    required this.onCancelScan,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Photo Analyzer',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      elevation: 2,
      actions: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton.icon(
              onPressed: onCancelScan,
              icon: const Icon(Icons.stop, color: Colors.red),
              label: const Text('Stop Scan', style: TextStyle(color: Colors.red)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton.icon(
            onPressed: onExit,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Exit'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}