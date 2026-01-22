class Coupon {
  final String code;
  final String issuer;
  final int discount;
  final DateTime? expiryDate;
  int? id;

  Coupon({
    this.id,
    required this.code,
    required this.issuer,
    required this.discount,
    this.expiryDate,
  });

  Coupon.fromJSON(Map<String, dynamic> map)
      : code = map['code'] ?? '',
        issuer = map['issuer'] ?? '',
        discount = map['discount'] ?? 0,
        expiryDate = map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null;

  bool isValid() {
    if (expiryDate == null) 
      return true;
      
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Returns true if the coupon will expire within the next 7 days.
  bool isExpiringSoon() {
    if (expiryDate == null) 
      return false;

    final now = DateTime.now();
    final inAWeek = now.add(Duration(days: 7));
    return now.isBefore(expiryDate!) && expiryDate!.isBefore(inAWeek);
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount': discount,
      'expiryDate': expiryDate?.toIso8601String(),
      'issuer': issuer,
    };
  }
}