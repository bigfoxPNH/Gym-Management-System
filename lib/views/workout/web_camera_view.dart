import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebCameraView extends StatelessWidget {
  const WebCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              kIsWeb ? Icons.videocam_off : Icons.error_outline,
              color: kIsWeb ? Colors.grey : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                  ? 'Camera functionality is currently disabled'
                  : 'Camera feature is only available on web platform',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
