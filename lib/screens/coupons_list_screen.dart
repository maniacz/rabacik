import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:rabacik/data/db_helper.dart';
import 'package:rabacik/data/models/coupon.dart';
import 'package:rabacik/screens/add_coupon_screen.dart';
import 'package:rabacik/screens/coupon_image_screen.dart';

class CouponsListScreen extends StatelessWidget {
  const CouponsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje kupony rabatowe'),),
      body: CouponsListBody(),
    );
  }

}

class CouponsListBody extends StatefulWidget {
  @override
  State<CouponsListBody> createState() => _CouponsListBodyState();
}

class _CouponsListBodyState extends State<CouponsListBody> {
  late Future<List<Coupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = getCoupons();
  }

  Future<void> _refreshCoupons() async {
    setState(() {
      _couponsFuture = getCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Coupon>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        final List<Dismissible> listTiles = [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
            return Center(child: Text('Error ${snapshot.error}'),);
        } else {
          for (Coupon coupon in snapshot.data!) {
            String couponText = coupon.expiryDate == null
            ? '${coupon.discount}% - bez daty ważności - ${coupon.issuer}'
            : '${coupon.discount}% - ważny do ${coupon.expiryDate.toString().split(' ')[0]} - ${coupon.issuer}';

            listTiles.add(Dismissible(
              key: Key(coupon.id.toString()),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                DbHelper helper = DbHelper();
                await helper.deleteCoupon(coupon.id!);
                await _refreshCoupons();
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: (coupon.imagePath != null && coupon.imagePath!.isNotEmpty && File(coupon.imagePath!).existsSync())
                    ? GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CouponImageScreen(imagePath: coupon.imagePath!),
                            ),
                          );
                        },
                        child: Image.file(
                          File(coupon.imagePath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.no_photography,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                title: Row(
                  children: [
                    Text(coupon.code),
                    if (coupon.isExpiringSoon()) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(couponText),
                    if (coupon.isExpiringSoon())
                      const Text(
                        'UWAGA: Kupon wkrótce wygaśnie!',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final isCouponEdited = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddCouponScreen(coupon: coupon, isEditMode: true),
                      ),
                    );
                    if (isCouponEdited) {
                      await _refreshCoupons();
                    }
                  },
                ),
              ),
            ));
          }
        }
        return ListView(children: listTiles,);
      },
    );
  }

  Future<List<Coupon>> getCoupons() async {
    DbHelper helper = DbHelper();
    final coupons = await helper.getCoupons();
    return coupons;
  }
}