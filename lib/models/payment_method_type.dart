import 'payment_method_field.dart';

class PaymentMethodType {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PaymentMethodField> fields;

  PaymentMethodType({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.fields,
  });

  factory PaymentMethodType.fromJson(Map<String, dynamic> json) {
    return PaymentMethodType(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      fields: json['fields'] != null
          ? (json['fields'] as List)
              .map((field) => PaymentMethodField.fromJson(Map<String, dynamic>.from(field)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fields': fields.map((field) => field.toJson()).toList(),
    };
  }
} 