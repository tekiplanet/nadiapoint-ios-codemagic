enum FiatTransactionType { deposit, withdraw, purchase }

class FiatTransaction {
  final String id;
  final String reference;
  final FiatTransactionType type;
  final String currency;
  final double amount;
  final double fee;
  final double totalAmount;
  final String status;
  final DateTime date;
  final double? cryptoAmount; // Only for purchase
  final double? exchangeRate; // Only for purchase
  final String? cryptoSymbol; // Only for purchase

  FiatTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.currency,
    required this.amount,
    required this.fee,
    required this.totalAmount,
    required this.status,
    required this.date,
    this.cryptoAmount,
    this.exchangeRate,
    this.cryptoSymbol,
  });

  static double _parseAmount(dynamic value) {
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    if (value is Map && value['amount'] != null)
      return double.tryParse(value['amount'].toString()) ?? 0.0;
    return 0.0;
  }

  static String _parseCurrency(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['code'] != null) return value['code'].toString();
    return '';
  }

  factory FiatTransaction.fromDepositJson(Map<String, dynamic> json) {
    return FiatTransaction(
      id: json['id'],
      reference: json['transactionId'],
      type: FiatTransactionType.deposit,
      currency: _parseCurrency(json['currency']),
      amount: _parseAmount(json['amount']),
      fee: _parseAmount(json['fee']),
      totalAmount: _parseAmount(json['totalAmount']),
      status: json['status'],
      date: DateTime.parse(json['createdAt'].toString()),
    );
  }

  factory FiatTransaction.fromWithdrawJson(Map<String, dynamic> json) {
    return FiatTransaction(
      id: json['id'],
      reference: json['transactionId'],
      type: FiatTransactionType.withdraw,
      currency: _parseCurrency(json['currency']),
      amount: _parseAmount(json['amount']),
      fee: _parseAmount(json['fee']),
      totalAmount: _parseAmount(json['totalAmount']),
      status: json['status'],
      date: DateTime.parse(json['createdAt'].toString()),
    );
  }

  factory FiatTransaction.fromPurchaseJson(Map<String, dynamic> json) {
    return FiatTransaction(
      id: json['id'],
      reference: json['transactionId'],
      type: FiatTransactionType.purchase,
      currency:
          _parseCurrency(json['fiatWallet']?['currency'] ?? json['currency']),
      amount: _parseAmount(json['fiatAmount']),
      fee: _parseAmount(json['fee']),
      totalAmount: _parseAmount(json['totalAmount']),
      status: json['status'],
      date: DateTime.parse(json['createdAt'].toString()),
      cryptoAmount: _parseAmount(json['cryptoAmount']),
      exchangeRate: _parseAmount(json['exchangeRate']),
      cryptoSymbol:
          json['token'] != null ? json['token']['symbol']?.toString() : null,
    );
  }
}
