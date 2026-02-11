import 'package:flutter/material.dart';
import 'package:rabacik/screens/add_coupon_screen.dart';
import 'package:rabacik/screens/coupons_list_screen.dart';
import 'package:rabacik/screens/scan_coupon_screen.dart';
import 'package:rabacik/data/models/coupon.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Country.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment(0, 0.8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddCouponScreen(),
                  ),
                );
              },
              child: Text('Dodaj kod rabatowy'))
          ),
          Align(
            alignment: Alignment(0, 0.6),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CouponsListScreen(),
                  ),
                );
              },
              child: Text('Moje kody rabatowe'))
          ),
          Align(
            alignment: Alignment(0, 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      final imageFile = File(pickedFile.path);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanCouponScreen(imageFile: imageFile),
                        ),
                      );
                    }
                  },
                  child: Text('Zrób zdjęcie kuponu'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final imageFile = File(pickedFile.path);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanCouponScreen(imageFile: imageFile),
                        ),
                      );
                    }
                  },
                  child: Text('Wybierz z galerii'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}