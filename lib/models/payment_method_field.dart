class PaymentMethodField {
  final String id;
  final String name;
  final String label;
  final String type;
  final String? placeholder;
  final String? helpText;
  final Map<String, dynamic>? validationRules;
  final bool isRequired;
  final int order;
  final String paymentMethodTypeId;
  final String createdAt;
  final String updatedAt;

  PaymentMethodField({
    required this.id,
    required this.name,
    required this.label,
    required this.type,
    this.placeholder,
    this.helpText,
    this.validationRules,
    required this.isRequired,
    required this.order,
    required this.paymentMethodTypeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethodField.fromJson(Map<String, dynamic> json) {
    return PaymentMethodField(
      id: json['id'] as String,
      name: json['name'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      validationRules: json['validationRules'] as Map<String, dynamic>?,
      isRequired: json['isRequired'] as bool,
      order: json['order'] as int,
      paymentMethodTypeId: json['paymentMethodTypeId'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'type': type,
      'placeholder': placeholder,
      'helpText': helpText,
      'validationRules': validationRules,
      'isRequired': isRequired,
      'order': order,
      'paymentMethodTypeId': paymentMethodTypeId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
} 