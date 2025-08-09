class ExchangeRate {
  final String currency;
  final double rate;
  final DateTime lastUpdated;

  ExchangeRate({
    required this.currency,
    required this.rate,
    required this.lastUpdated,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      currency: json['currency'],
      rate: json['rate'].toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
} 