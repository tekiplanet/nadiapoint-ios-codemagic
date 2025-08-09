import 'package:flutter/material.dart';

class MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  MiniSparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width / (data.length - 1);
    
    path.moveTo(0, size.height * (1 - data[0]));
    
    for (var i = 1; i < data.length; i++) {
      path.lineTo(width * i, size.height * (1 - data[i]));
    }

    canvas.drawPath(path, paint);

    // Draw gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.2),
        color.withOpacity(0),
      ],
    );

    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 