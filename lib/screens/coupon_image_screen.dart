import 'dart:io';
import 'package:flutter/material.dart';

class CouponImageScreen extends StatelessWidget {
  final String imagePath;
  const CouponImageScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zdjęcie kuponu')),
      body: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
