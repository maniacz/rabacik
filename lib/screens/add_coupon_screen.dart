import 'package:flutter/material.dart';
import 'package:rabacik/data/db_helper.dart';
import 'package:rabacik/data/models/coupon.dart';

class AddCouponScreen extends StatefulWidget {

  final Coupon? coupon;
  const AddCouponScreen({super.key, this.coupon});

  @override
  State<StatefulWidget> createState() => _AddCouponScreenState();

}

class _AddCouponScreenState extends State<AddCouponScreen> {
  DateTime? _selectedDate;
  String? _couponCode;
  String? _couponIssuer;
  double? _discount;

  @override
  void initState() {
    super.initState();
    if (widget.coupon != null) {
      _couponCode = widget.coupon!.code;
      _couponIssuer = widget.coupon!.issuer;
      _selectedDate = widget.coupon!.expiryDate;
      _discount = widget.coupon!.discount;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.coupon == null ? 'Dodaj kod rabatowy' : 'Edytuj kod rabatowy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // spacing: 20, // spacing is not a property of Column
          children: [
            TextField(
              controller: TextEditingController(text: _couponCode),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Wpisz kod rabatowy',
              ),
              onChanged: (value) {
                _couponCode = value;
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: _couponIssuer),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Gdzie działa kod rabatowy',
              ),
              onChanged: (value) {
                _couponIssuer = value;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Ważny do: '),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
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
                Text(_selectedDate == null
                    ? 'Nie wybrano daty'
                    : '\t${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'),
              ],
            ),
            const SizedBox(height: 20),
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
                      // id: widget.coupon?.id,
                      code: _couponCode ?? '',
                      issuer: _couponIssuer ?? '',
                      discount: widget.coupon?.discount ?? 15.0,
                      expiryDate: _selectedDate ?? DateTime.now(),
                    );
                    if (widget.coupon == null) {
                      // Add new coupon
                      helper.insertCoupon(coupon).then((id) {
                        final message = (id > 0)
                            ? 'Dodano kupon o id: $id'
                            : 'Wystąpił błąd podczas dodawania kuponu';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
                        );
                        Navigator.of(context).pop();
                      });
                    } else {
                      // Update existing coupon
                      helper.updateCoupon(coupon).then((isUpdateSuccessful) {
                        final message = (isUpdateSuccessful)
                            ? 'Zaktualizowano kupon'
                            : 'Wystąpił błąd podczas aktualizacji kuponu';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
                        );
                        Navigator.of(context).pop();
                      });
                    }
                  },
                  child: Text(widget.coupon == null ? 'Zapisz' : 'Aktualizuj'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}