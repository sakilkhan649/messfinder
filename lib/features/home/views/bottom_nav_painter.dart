import 'package:flutter/material.dart';

class BottomNavBorderPainter extends CustomPainter {
  final double fabSize;
  final double notchMargin;
  final Color borderColor;
  final Color shadowColor;

  BottomNavBorderPainter({
    this.fabSize = 72.0, // Match the FAB size exactly (72x72)
    this.notchMargin = 12.0, // Match the margin (12)
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Create the path for the notched rectangle
    final host = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // FAB is centerDocked. Its center is precisely at the top edge of the BottomAppBar
    final guest = Rect.fromLTWH(
      (size.width - fabSize) / 2,
      -fabSize / 2,
      fabSize,
      fabSize,
    );

    final shape = const CircularNotchedRectangle();
    final path = shape.getOuterPath(host, guest.inflate(notchMargin));

    // 2. Draw the shadow ONLY at the top
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    
    canvas.save();
    // Clip the bottom area so no shadow bleeds down at the bottom edge.
    canvas.clipRect(Rect.fromLTRB(-50, -50, size.width + 50, size.height - 10));
    // Translate the shadow UPWARDS
    canvas.translate(0, -6);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 3. Draw the solid white background of the navbar
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 4. Draw the crisp top border, excluding left, right, and bottom edges
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    
    canvas.save();
    // Clip 1 pixel inward from left, right, and bottom to hide those border lines.
    // The top edge and the notch remain perfectly within the clip area!
    canvas.clipRect(Rect.fromLTRB(1.0, -50.0, size.width - 1.0, size.height - 1.0));
    canvas.drawPath(path, borderPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
