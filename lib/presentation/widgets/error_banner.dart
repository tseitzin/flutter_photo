// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final int accessErrorsCount;
  final int unscannedDirectoriesCount;
  final VoidCallback onTap;

  const ErrorBanner({
    super.key,
    required this.accessErrorsCount,
    required this.unscannedDirectoriesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                'Errors: $accessErrorsCount scanning error${accessErrorsCount != 1 ? 's' : ''}, $unscannedDirectoriesCount inaccessible director${unscannedDirectoriesCount != 1 ? 'ies' : 'y'}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}