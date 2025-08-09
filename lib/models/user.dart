class User {
  final String id;
  final String email;
  final String? name;
  final bool isEmailVerified;
  final bool is2FAEnabled;
  final bool biometricEnabled; // For biometric authentication
  final String? traderId;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    this.isEmailVerified = false,
    this.is2FAEnabled = false,
    this.biometricEnabled = false,
    this.traderId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      is2FAEnabled: json['is2FAEnabled'] ?? false,
      biometricEnabled: json['biometricEnabled'] ?? false,
      traderId: json['traderId'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isEmailVerified': isEmailVerified,
      'is2FAEnabled': is2FAEnabled,
      'biometricEnabled': biometricEnabled,
      'traderId': traderId,
      'createdAt': createdAt,
    };
  }
}
