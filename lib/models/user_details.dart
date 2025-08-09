class UserDetails {
  final String fullName;
  final String email;
  final bool emailVerified;
  final bool phoneVerified;

  UserDetails({
    required this.fullName,
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      fullName: json['fullName'],
      email: json['email'],
      emailVerified: json['emailVerified'],
      phoneVerified: json['phoneVerified'],
    );
  }
} 