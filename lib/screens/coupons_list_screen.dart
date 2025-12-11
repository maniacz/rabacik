import 'package:flutter/material.dart';
import 'package:rabacik/data/db_helper.dart';
import 'package:rabacik/data/models/coupon.dart';

class CouponsListScreen extends StatelessWidget {
  const CouponsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje kupony rabatowe'),),
      body: FutureBuilder(
        future: getCoupons(),
        builder: (context, snapshot) {
          final List<ListTile> listTiles = [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error ${snapshot.error}'),);
          } else {
            for (Coupon coupon in snapshot.data!) {
              listTiles.add(ListTile(
                title: Text(coupon.code),
                subtitle: Text(coupon.discount.toString()),
              ));
            }
          }
          return ListView(children: listTiles,);
        }
      )
    );
  }

  Future<List<Coupon>> getCoupons() async {
    DbHelper helper = DbHelper();
    final coupons = await helper.getCoupons();
    return coupons;
  }
}