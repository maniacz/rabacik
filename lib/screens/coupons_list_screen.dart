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
  String _sortOption = 'expiryDateDesc';
  bool _showArchived = false;
  static const Map<String, String> _sortOptions = {
    'expiryDateAsc': 'Data rosnąco',
    'expiryDateDesc': 'Data malejąco',
    'issuer': 'Wystawca (A-Z)',
  };

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Sortuj:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortOption,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                items: _sortOptions.entries
                    .map((entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortOption = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              Text('Pokaż zarchiwizowane', style: TextStyle(fontSize: 13)),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _showArchived,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) {
                    setState(() {
                      _showArchived = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Coupon>>(
            future: _couponsFuture,
            builder: (context, snapshot) {
              final List<Dismissible> listTiles = [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error {snapshot.error}'),);
              } else {
                List<Coupon> coupons = List.from(snapshot.data!);
                // Filtrowanie zarchiwizowanych
                if (!_showArchived) {
                  coupons = coupons.where((c) => !c.isExpired()).toList();
                }
                if (_sortOption == 'issuer') {
                  coupons.sort((a, b) => (a.issuer ?? '').toLowerCase().compareTo((b.issuer ?? '').toLowerCase()));
                } else if (_sortOption == 'expiryDateAsc') {
                  coupons.sort((a, b) {
                    if (a.expiryDate == null && b.expiryDate == null) return 0;
                    if (a.expiryDate == null) return 1;
                    if (b.expiryDate == null) return -1;
                    return a.expiryDate!.compareTo(b.expiryDate!);
                  });
                } else if (_sortOption == 'expiryDateDesc') {
                  coupons.sort((a, b) {
                    if (a.expiryDate == null && b.expiryDate == null) return 0;
                    if (a.expiryDate == null) return 1;
                    if (b.expiryDate == null) return -1;
                    return b.expiryDate!.compareTo(a.expiryDate!);
                  });
                }
                for (Coupon coupon in coupons) {
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
                          Text(
                            coupon.code,
                            style: coupon.isExpired()
                                ? const TextStyle(color: Colors.grey)
                                : null,
                          ),
                          if (coupon.isExpiringSoon()) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            couponText,
                            style: coupon.isExpired()
                                ? const TextStyle(color: Colors.grey)
                                : null,
                          ),
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
                          if (isCouponEdited == true) {
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
          ),
        ),
      ],
    );
  }

  Future<List<Coupon>> getCoupons() async {
    DbHelper helper = DbHelper();
    final coupons = await helper.getCoupons();
    return coupons;
  }
}