import 'package:flutter/material.dart';
import 'package:rabacik/data/db_helper.dart';
import 'package:rabacik/data/models/coupon.dart';

class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AddCouponScreenState();

}

class _AddCouponScreenState extends State<AddCouponScreen> {
  DateTime? _selectedDate;
  String? _couponCode;
  String? _couponIssuer;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj kod rabatowy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Wpisz kod rabatowy',
              ),
              onSubmitted: (String value) => {
                _couponCode = value
              },
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gdzie działa kod rabatowy',
              ),
              onSubmitted: (String value) => {
                _couponIssuer = value
              },
            ),
            Row(
              children: [
                const Text('Ważny do: '),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Wybierz datę'),
                ),
                Text( _selectedDate == null
                  ? 'Nie wybrano daty'
                  : '\t${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                ), 
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DbHelper helper = DbHelper();
                    Coupon coupon = Coupon(
                      code: _couponCode ?? '',
                      issuer: _couponIssuer ?? '',
                      discount: 15.0, 
                      expiryDate: _selectedDate ?? DateTime.now()
                    );
                    print('Dodano kupon: ${coupon.code}');
                    helper.insertCoupon(coupon)
                      .then((id) {
                        final message = (id > 0) 
                          ? 'Dodano kupon o id: $id' 
                          : 'Wystąpił błąd podczas dodawania kuponu';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), duration: Duration(seconds: 2),)
                        );
                      });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}