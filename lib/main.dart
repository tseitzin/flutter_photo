import 'dart:io'; // Import for File class
import 'package:flutter/material.dart';
import 'package:file_picker_desktop/file_picker_desktop.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<File> _images = [];

  Future<void> _pickImage() async {
    print('Pick image button pressed'); // Debug log

    try {
      print('Showing file picker...'); // Debug log
      FilePickerResult? result = await pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
        dialogTitle: 'Select Images',
      );

      print('File picker result: $result'); // Debug log

      if (result != null) {
        setState(() {
          final newImages =
              result.paths
                  .where((path) => path != null)
                  .map((path) => File(path!))
                  .toList();
          print('Adding ${newImages.length} images'); // Debug log
          _images.addAll(newImages);
        });
      } else {
        print('No files selected'); // Debug log
      }
    } catch (e) {
      print('Error picking image: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Image Sorting Tool')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Select Images'),
              ),
              Expanded(
                // Use Expanded to fill available space
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Image.file(
                      _images[index],
                      fit: BoxFit.cover, // Adjust as needed
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
