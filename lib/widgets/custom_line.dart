/* ============================================================
   DASHED LINE
============================================================ */
import 'package:flutter/material.dart';
import 'package:konek2move/utils/app_colors.dart';
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 3.0;
    const dashSpace = 3.0;
    double startY = 0;
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset.zero.translate(0, startY),
        Offset.zero.translate(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}