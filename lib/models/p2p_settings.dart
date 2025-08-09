class P2PSettings {
  final String currency;
  // ... other settings

  P2PSettings.fromJson(Map<String, dynamic> json)
    : currency = json['currency'] ?? 'NGN';
} 