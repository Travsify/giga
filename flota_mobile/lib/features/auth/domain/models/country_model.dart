class Country {
  final int id;
  final String name;
  final String isoCode;
  final String currencyCode;
  final String currencySymbol;
  final String phoneCode;
  final List<String> paymentGateways; // ['stripe', 'paystack']
  final List<String> features; // ['wallet', 'cod']
  final bool isDefault;

  Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.phoneCode,
    required this.paymentGateways,
    required this.features,
    required this.isDefault,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name'],
      isoCode: json['iso_code'],
      currencyCode: json['currency_code'],
      currencySymbol: json['currency_symbol'],
      phoneCode: json['phone_code'],
      paymentGateways: List<String>.from(json['payment_gateways'] ?? []),
      features: List<String>.from(json['features'] ?? []),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }
}
