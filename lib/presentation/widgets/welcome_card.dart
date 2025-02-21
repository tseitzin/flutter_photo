import 'package:flutter/material.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 28),
                  SizedBox(width: 16),
                  Text(
                    'Welcome to Photo Analyzer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This application helps you analyze and organize your photo collection by:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Scanning directories for image files'),
                    Text('• Counting images in each folder'),
                    Text('• Providing a detailed breakdown of your photo collection'),
                    Text('• Identifying inaccessible directories'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'How to use:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Click "Select Directory" to choose a folder to analyze'),
                    Text('2. Wait for the scan to complete'),
                    Text('3. Review the analysis results'),
                    Text('4. Use the "Stop Scan" button if you need to cancel'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}