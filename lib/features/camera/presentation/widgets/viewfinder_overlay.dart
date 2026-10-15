import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';

/// Framing guide overlay widget with animated scanning line and corner brackets.
class ViewfinderOverlay extends StatefulWidget {
  final Rect cutoutRect;

  const ViewfinderOverlay({
    super.key,
    required this.cutoutRect,
  });

  @override
  State<ViewfinderOverlay> createState() => _ViewfinderOverlayState();
}

class _ViewfinderOverlayState extends State<ViewfinderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ViewfinderPainter(
            cutout: widget.cutoutRect,
            scanProgress: _scanAnimation.value,
          ),
        );
      },
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Rect cutout;
  final double scanProgress;

  _ViewfinderPainter({
    required this.cutout,
    required this.scanProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dim background outside receipt cutout window
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutout, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(bgPath, bgPaint);

    // 2. Window border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutout, const Radius.circular(16)),
      borderPaint,
    );

    // 3. Four corner alignment brackets
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primaryLight;

    const cornerLength = 28.0;
    const cornerRadius = 16.0;

    // Top-Left
    final tlPath = Path()
      ..moveTo(cutout.left, cutout.top + cornerLength)
      ..lineTo(cutout.left, cutout.top + cornerRadius)
      ..arcToPoint(
        Offset(cutout.left + cornerRadius, cutout.top),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(cutout.left + cornerLength, cutout.top);
    canvas.drawPath(tlPath, bracketPaint);

    // Top-Right
    final trPath = Path()
      ..moveTo(cutout.right - cornerLength, cutout.top)
      ..lineTo(cutout.right - cornerRadius, cutout.top)
      ..arcToPoint(
        Offset(cutout.right, cutout.top + cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(cutout.right, cutout.top + cornerLength);
    canvas.drawPath(trPath, bracketPaint);

    // Bottom-Left
    final blPath = Path()
      ..moveTo(cutout.left, cutout.bottom - cornerLength)
      ..lineTo(cutout.left, cutout.bottom - cornerRadius)
      ..arcToPoint(
        Offset(cutout.left + cornerRadius, cutout.bottom),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(cutout.left + cornerLength, cutout.bottom);
    canvas.drawPath(blPath, bracketPaint);

    // Bottom-Right
    final brPath = Path()
      ..moveTo(cutout.right - cornerLength, cutout.bottom)
      ..lineTo(cutout.right - cornerRadius, cutout.bottom)
      ..arcToPoint(
        Offset(cutout.right, cutout.bottom - cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(cutout.right, cutout.bottom - cornerLength);
    canvas.drawPath(brPath, bracketPaint);

    // 4. Animated Scanning Line
    final scanY = cutout.top + (cutout.height * scanProgress);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.0),
          AppColors.primaryLight.withValues(alpha: 0.9),
          AppColors.accent,
          AppColors.primaryLight.withValues(alpha: 0.9),
          AppColors.primaryLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cutout.left, scanY, cutout.width, 2.5))
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(cutout.left + 8, scanY),
      Offset(cutout.right - 8, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.cutout != cutout;
  }
}

