import 'dart:io';

import 'package:flutter/material.dart';

class FullscreenImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullscreenImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: imageUrl.startsWith('http')
              ? Image.network(imageUrl)
              : Image.file(File(imageUrl)),
        ),
      ),
    );
  }
}
