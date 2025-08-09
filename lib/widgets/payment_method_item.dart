import 'package:flutter/material.dart';
import 'package:dotenv/dotenv.dart';
import 'package:safejet_exchange/models/payment_method.dart';

DotEnv dotenv = DotEnv();

Widget _buildDetailValue(PaymentMethodDetail detail) {
  if (detail.fieldType == 'image') {
    final baseUrl = dotenv.env['API_URL'] ?? '';
    return Image.network(
      detail.getImageUrl(baseUrl),
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }
  return Text(detail.value);
} 