import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/image_base64_service.dart';

class ImageTestScreen extends StatefulWidget {
  @override
  _ImageTestScreenState createState() => _ImageTestScreenState();
}

class _ImageTestScreenState extends State<ImageTestScreen> {
  String? testImageBase64;

  Future<void> testImagePick() async {
    print('Testing image pick...');

    try {
      final result = await ImageBase64Service.pickAndConvertImage();
      print('Result: $result');

      if (result != null) {
        setState(() {
          testImageBase64 = result;
        });
        print('Image converted successfully! Length: ${result.length}');
      } else {
        print('No image selected or conversion failed');
      }
    } catch (e) {
      print('Error during test: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Test')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: testImagePick,
            child: Text('Test Image Pick'),
          ),
          if (testImageBase64 != null) ...[
            Text('Image loaded successfully!'),
            Text('Length: ${testImageBase64!.length} characters'),
            Container(
              width: 200,
              height: 200,
              child: Image.memory(
                ImageBase64Service.base64ToBytes(testImageBase64!)!,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
