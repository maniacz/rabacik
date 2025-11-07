class Coupon {
  final String code;
  final double discount;
  final DateTime expiryDate;

  Coupon({
    required this.code,
    required this.discount,
    required this.expiryDate,
  });

  bool isValid() {
    return DateTime.now().isBefore(expiryDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount': discount,
      'expiryDate': expiryDate
    };
  }
}