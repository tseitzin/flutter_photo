import 'package:flutter/material.dart';

class SelectDirectoryButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSelectDirectory;

  const SelectDirectoryButton({
    super.key,
    required this.isLoading,
    required this.onSelectDirectory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onSelectDirectory,
        icon: const Icon(Icons.folder_open),
        label: const Text('Select Directory'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}