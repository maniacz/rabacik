import 'package:flutter/material.dart';
import 'package:rabacik/screens/add_coupon_screen.dart';
import 'package:rabacik/screens/coupons_list_screen.dart';
import 'package:rabacik/screens/scan_coupon_screen.dart';
import 'package:rabacik/data/models/coupon.dart';

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
              onPressed: () async {
                final result = await Navigator.of(context).push<Map<String, String>>(
                  MaterialPageRoute(
                    builder: (context) => const ScanCouponScreen(),
                  ),
                );
                if (result != null) {
                  String code = result['code'] ?? '';
                  String issuer = result['issuer'] ?? '';
                  String expiry = result['expiry'] ?? '';
                  int discount = int.tryParse(result['discount'] ?? '') ?? 0;
                  DateTime? expiryDate;
                  try {
                    expiryDate = DateTime.tryParse(expiry);
                  } catch (_) {
                    expiryDate = null;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddCouponScreen(
                        coupon: Coupon(
                          code: code,
                          issuer: issuer,
                          discount: discount,
                          expiryDate: expiryDate,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Text('Skanuj kupon'),
            ),
          ),
        ],
      ),
    );
  }
}