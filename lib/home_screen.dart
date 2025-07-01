import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'process_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<XFile>? _images;
  final ImagePicker _picker = ImagePicker();

  String _selectedFormat = 'PDF';
  double _compressionLevel = 0.8;

  Future<void> _pickImages() async {
    final List<XFile>? selectedImages = await _picker.pickMultiImage();
    if (selectedImages != null && selectedImages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessScreen(images: selectedImages),
        ),
      );
    }
  }

  Widget _buildFormatRadio(String format) {
    return Row(
      children: [
        Radio<String>(
          value: format,
          groupValue: _selectedFormat,
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
        ),
        Text(format),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Image Converter'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Image Converter',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 90,
            backgroundColor: Colors.deepPurple.shade100,
            child: Icon(
              Icons.image,
              size: 90,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _pickImages,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text(
              'Select Images',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

        ],
      ),
    );
  }
}
