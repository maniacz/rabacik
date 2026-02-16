import 'package:flutter/material.dart';
import 'package:rabacik/data/db_helper.dart';
import 'package:rabacik/data/models/coupon.dart';
import 'package:rabacik/data/notification_helper.dart';
import 'package:flutter/services.dart';
import '../route_logger.dart';
import '../main.dart';
import 'package:rabacik/data/logger/local_logger.dart';
import 'package:rabacik/data/logger/logger.dart';
import 'dart:io';

class AddCouponScreen extends StatefulWidget {
  final Coupon? coupon;
  final bool isEditMode;
  const AddCouponScreen({super.key, this.coupon, this.isEditMode = false});

  @override
  State<StatefulWidget> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final LoggingRouteAware _routeAware = LoggingRouteAware('AddCouponScreen');
  final Logger _logger = LocalLogger();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(_routeAware, ModalRoute.of(context)! as PageRoute);
  }

  DateTime? _selectedDate;
  String? _couponCode;
  String? _couponIssuer;
  int? _discount;
  String? _couponCodeError;
  String? _couponIssuerError;
  String? _discountError;
  late TextEditingController _discountController;
  late TextEditingController _couponCodeController;
  late TextEditingController _couponIssuerController;
  int? _updatedCouponId;

  @override
  void initState() {
    super.initState();
    if (widget.coupon != null) {
      _couponCode = widget.coupon!.code;
      _couponIssuer = widget.coupon!.issuer;
      _selectedDate = widget.coupon!.expiryDate;
      _discount = widget.coupon!.discount;
    }
    _couponCodeController = TextEditingController(text: _couponCode ?? '');
    _couponIssuerController = TextEditingController(text: _couponIssuer ?? '');
    _discountController = TextEditingController(
      text: _discount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    _couponIssuerController.dispose();
    _discountController.dispose();
    routeObserver.unsubscribe(_routeAware);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edytuj kod rabatowy' : 'Dodaj kod rabatowy',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.coupon?.imagePath != null && widget.coupon!.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Image.file(
                  File(widget.coupon!.imagePath!),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            TextField(
              controller: _couponCodeController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Wpisz kod rabatowy',
                errorText: _couponCodeError,
              ),
              onChanged: (value) {
                setState(() {
                  _couponCode = value;
                  if (value.trim().isEmpty) {
                    _couponCodeError = 'Kod rabatowy nie może być pusty';
                  } else {
                    _couponCodeError = null;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _couponIssuerController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Gdzie działa kod rabatowy',
                errorText: _couponIssuerError,
              ),
              onChanged: (value) {
                setState(() {
                  _couponIssuer = value;
                  if (value.trim().isEmpty) {
                    _couponIssuerError = 'Pole nie może być puste';
                  } else {
                    _couponIssuerError = null;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Wpisz wartość rabatu (%)',
                errorText: _discountError,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (value) {
                int? val = int.tryParse(value);
                setState(() {
                  if (value.isEmpty) {
                    _discount = null;
                    _discountError = 'Wartość rabatu nie może być pusta';
                  } else if (val != null && val >= 1 && val <= 100) {
                    _discount = val;
                    _discountError = null;
                  } else {
                    _discount = null;
                    _discountError =
                        'Wartość rabatu musi być liczbą całkowitą od 1 do 100';
                  }
                });
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
                Text(
                  _selectedDate == null
                      ? 'Nie wybrano daty'
                      : '\t${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
                ),
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
                  onPressed: () async {
                    setState(() {
                      _couponCodeError =
                          (_couponCode == null || _couponCode!.trim().isEmpty)
                          ? 'Kod rabatowy nie może być pusty'
                          : null;
                      _couponIssuerError =
                          (_couponIssuer == null ||
                              _couponIssuer!.trim().isEmpty)
                          ? 'Pole nie może być puste'
                          : null;
                      _discountError = (_discount == null)
                          ? 'Wartość rabatu nie może być pusta'
                          : _discountError;
                      _discountError =
                          (_discount != null &&
                              (_discount! < 1 || _discount! > 100))
                          ? 'Wartość rabatu musi być liczbą całkowitą od 1 do 100'
                          : _discountError;
                    });
                    if (_couponCodeError != null ||
                        _couponIssuerError != null ||
                        _discountError != null) {
                      // Do not proceed if there are errors
                      return;
                    }
                    // If expiry date is not selected, show confirmation dialog
                    if (_selectedDate == null) {
                      final shouldSave = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Brak daty ważności'),
                          content: const Text(
                            'Czy na pewno chcesz dodać kupon bez daty ważności?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Nie'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Tak'),
                            ),
                          ],
                        ),
                      );
                      if (shouldSave != true) {
                        // User cancelled, return to editing
                        return;
                      }
                    }
                    DbHelper helper = DbHelper();
                    Coupon coupon = Coupon(
                      id: widget.coupon?.id,
                      code: _couponCode ?? '',
                      issuer: _couponIssuer ?? '',
                      discount: _discount ?? 0,
                      expiryDate: _selectedDate,
                      imagePath: widget.coupon?.imagePath,
                    );
                    if (!widget.isEditMode) {
                      // Add new coupon
                      helper.insertCoupon(coupon).then((id) async {
                        final message = (id > 0)
                            ? 'Dodano kupon o id: $id'
                            : 'Wystąpił błąd podczas dodawania kuponu';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        if (id > 0) {
                          // Schedule local notification for expiry
                          if (coupon.expiryDate != null) {
                            await NotificationHelper.scheduleCouponExpiryNotification(
                              id: id,
                              code: coupon.code,
                              expiryDate: coupon.expiryDate!,
                            );
                          }
                          // Powrót na ekran startowy po dodaniu kuponu
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        } else {
                          _logger.log('Błąd podczas dodawania kuponu', error: 'insertCoupon zwrócił id <= 0');
                        }
                      }).catchError((error, stackTrace) {
                        _logger.log('Wyjątek podczas dodawania kuponu', error: error, stackTrace: stackTrace);
                      });
                    } else {
                      // Update existing coupon
                      helper.updateCoupon(coupon).then((isUpdateSuccessful) {
                        final message = (isUpdateSuccessful)
                            ? 'Zaktualizowano kupon od ${coupon.issuer}'
                            : 'Wystąpił błąd podczas aktualizacji kuponu';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        if (isUpdateSuccessful) {
                          Navigator.of(
                            context,
                          ).pop();
                        } else {
                          _logger.log('Błąd podczas aktualizacji kuponu', error: 'updateCoupon zwrócił false');
                        }
                      }).catchError((error, stackTrace) {
                        _logger.log('Wyjątek podczas aktualizacji kuponu', error: error, stackTrace: stackTrace);
                      });
                    }
                  },
                  child: Text(widget.isEditMode ? 'Aktualizuj' : 'Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
