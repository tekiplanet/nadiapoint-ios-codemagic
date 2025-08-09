import 'package:flutter/material.dart';
import 'dart:math' show sin;
import '../config/theme/colors.dart';

class MiniChartPainter extends CustomPainter {
  final List<double> points;
  
  MiniChartPainter({this.points = const []});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      // Draw dummy data if no points provided
      _drawDummyChart(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = SafeJetColors.success
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final height = size.height;
    final width = size.width;

    // Find min and max for scaling
    final maxPrice = points.reduce((max, price) => price > max ? price : max);
    final minPrice = points.reduce((min, price) => price < min ? price : min);
    final priceRange = maxPrice - minPrice;

    // Start from the first point
    if (points.isNotEmpty) {
      final x = 0.0;
      final y = height - ((points[0] - minPrice) / priceRange * height);
      path.moveTo(x, y);

      // Draw line to each subsequent point
      for (var i = 1; i < points.length; i++) {
        final x = (i / (points.length - 1)) * width;
        final y = height - ((points[i] - minPrice) / priceRange * height);
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawDummyChart(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SafeJetColors.success
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final height = size.height;
    final width = size.width;

    path.moveTo(0, height * 0.5);

    for (var i = 0; i < 10; i++) {
      final x = width * (i / 9);
      final y = height * (0.3 + 0.4 * sin(i * 0.5));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 