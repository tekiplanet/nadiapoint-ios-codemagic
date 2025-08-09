import 'payment_method_type.dart';

class PaymentMethodDetail {
  final String value;
  final String fieldId;
  final String fieldType;
  final String fieldName;

  PaymentMethodDetail({
    required this.value,
    required this.fieldId,
    required this.fieldType,
    required this.fieldName,
  });

  String getImageUrl(String baseUrl) {
    if (fieldType == 'image') {
      return '$baseUrl/uploads/payment-methods/$value';
    }
    return value;
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'fieldId': fieldId,
    'fieldType': fieldType,
    'fieldName': fieldName,
  };

  factory PaymentMethodDetail.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDetail(
      value: json['value'] as String,
      fieldId: json['fieldId'] as String,
      fieldType: json['fieldType'] as String,
      fieldName: json['fieldName'] as String,
    );
  }
}

class PaymentMethod {
  final String id;
  final String userId;
  final String paymentMethodTypeId;
  final bool isDefault;
  final bool isVerified;
  final Map<String, PaymentMethodDetail> details;
  final String createdAt;
  final String updatedAt;
  final PaymentMethodType? paymentMethodType;
  final String? name;

  String get icon => paymentMethodType?.icon ?? 'account_balance';
  String get displayName => name ?? 'Unnamed Payment Method';

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.paymentMethodTypeId,
    required this.isDefault,
    required this.isVerified,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.paymentMethodType,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final detailsMap = json['details'] as Map<String, dynamic>;
    final details = detailsMap.map((key, value) => MapEntry(
      key,
      value is PaymentMethodDetail ? value : PaymentMethodDetail.fromJson(value),
    ));

    return PaymentMethod(
      id: json['id'] as String,
      userId: json['userId'] as String,
      paymentMethodTypeId: json['paymentMethodTypeId'] as String,
      isDefault: json['isDefault'] as bool,
      isVerified: json['isVerified'] as bool,
      details: details,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      name: json['name'] as String?,
      paymentMethodType: json['paymentMethodType'] != null 
          ? PaymentMethodType.fromJson(Map<String, dynamic>.from(json['paymentMethodType']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'paymentMethodTypeId': paymentMethodTypeId,
      'isDefault': isDefault,
      'isVerified': isVerified,
      'details': details.map((key, value) => MapEntry(key, value.toJson())),
      'name': name,
    };
  }
} 