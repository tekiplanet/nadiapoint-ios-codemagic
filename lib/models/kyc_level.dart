class KYCLevel {
  final String id;
  final int level;
  final String title;
  final List<String> requirements;
  final List<String> benefits;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> features;

  KYCLevel({
    required this.id,
    required this.level,
    required this.title,
    required this.requirements,
    required this.benefits,
    required this.limits,
    required this.features,
  });

  factory KYCLevel.fromJson(Map<String, dynamic> json) {
    return KYCLevel(
      id: json['id'],
      level: json['level'],
      title: json['title'],
      requirements: List<String>.from(json['requirements']),
      benefits: List<String>.from(json['benefits']),
      limits: json['limits'],
      features: json['features'],
    );
  }
} 