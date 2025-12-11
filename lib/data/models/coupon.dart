class Coupon {
  final String code;
  final String issuer;
  final double discount;
  final DateTime expiryDate;
  int? id;

  Coupon({
    required this.code,
    required this.issuer,
    required this.discount,
    required this.expiryDate,
  });

  Coupon.fromJSON(Map<String, dynamic> map)
    : code = map['code'] ?? '',
      issuer = map['issuer'] ?? '',
      discount = map['discount']?.toDouble() ?? 0.0,
      expiryDate = DateTime.parse(map['expiryDate'] ?? DateTime.now().toIso8601String());

  bool isValid() {
    return DateTime.now().isBefore(expiryDate);
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount': discount,
      'expiryDate': expiryDate.toIso8601String()
    };
  }
}