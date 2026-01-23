import 'package:flutter/material.dart';
import 'package:rabacik/screens/add_coupon_screen.dart';
import 'package:rabacik/screens/coupons_list_screen.dart';
import 'package:rabacik/screens/scan_coupon_screen.dart';

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
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ScanCouponScreen(),
                  ),
                );
              },
              child: Text('Skanuj kupon'),
            ),
          ),
        ],
      ),
    );
  }
}