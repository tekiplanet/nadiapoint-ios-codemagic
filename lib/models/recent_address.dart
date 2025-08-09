class RecentAddress {
  final String address;
  final String coin;
  final String network;
  final String? label;
  final DateTime lastUsed;

  const RecentAddress({
    required this.address,
    required this.coin,
    required this.network,
    this.label,
    required this.lastUsed,
  });

  // From JSON
  factory RecentAddress.fromJson(Map<String, dynamic> json) {
    return RecentAddress(
      address: json['address'],
      coin: json['coin'],
      network: json['network'],
      label: json['label'],
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coin': coin,
      'network': network,
      'label': label,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }
} 