import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================================================
// MODERN DUAL TREND CHART (Glow Line & Gradient Bars)
// ============================================================================

class AnimatedDualTrendChart extends StatelessWidget {
  const AnimatedDualTrendChart({
    super.key,
    required this.calories,
    required this.protein,
    required this.targetCalories,
    required this.targetProtein,
    required this.primaryColor,
    required this.secondaryColor,
    this.height = 220,
  });

  final List<double> calories;
  final List<double> protein;
  final double targetCalories;
  final double targetProtein;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(double.infinity, height),
          painter: _ModernDualTrendPainter(
            calories: calories,
            protein: protein,
            targetCalories: targetCalories,
            targetProtein: targetProtein,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            progress: value,
          ),
        );
      },
    );
  }
}

class _ModernDualTrendPainter extends CustomPainter {
  _ModernDualTrendPainter({
    required this.calories,
    required this.protein,
    required this.targetCalories,
    required this.targetProtein,
    required this.primaryColor,
    required this.secondaryColor,
    required this.progress,
  });

  final List<double> calories;
  final List<double> protein;
  final double targetCalories;
  final double targetProtein;
  final Color primaryColor;
  final Color secondaryColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (calories.isEmpty || protein.isEmpty) return;

    final int count = calories.length;
    final double width = size.width;
    final double height = size.height - 20; // Leave space for X-axis labels

    final barWidth = 14.0;
    final totalSpacing = width - (barWidth * count);
    final spacing = totalSpacing / (count <= 1 ? 1 : count - 1);

    final maxCal = math.max(targetCalories * 1.2, calories.reduce(math.max));
    final maxPro = math.max(targetProtein * 1.2, protein.reduce(math.max));

    // 1. Draw Target Line (Calories)
    final targetCalY = height - ((targetCalories / maxCal) * height);
    _drawDashedLine(
      canvas,
      width,
      targetCalY,
      Colors.grey.withValues(alpha: 0.3),
    );

    // 2. Draw Bars (Background Track + Foreground Gradient)
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < calories.length; i++) {
      final x = i * (barWidth + spacing);

      // Track (Background)
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Foreground bar
      final barHeight = (calories[i] / maxCal) * height * progress;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, height - barHeight, barWidth, barHeight),
        const Radius.circular(8),
      );

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(barRect.outerRect)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(barRect, gradientPaint);
    }

    // 3. Draw Protein Line with Glow
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < protein.length; i++) {
      final x = i * (barWidth + spacing) + (barWidth / 2);
      final lineY = height - ((protein[i] / maxPro) * height * progress);
      final point = Offset(x, lineY);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, lineY);
      } else {
        final prevX = points[i - 1].dx;
        final prevY = points[i - 1].dy;
        final cp1x = prevX + (x - prevX) / 2;
        final cp1y = prevY;
        final cp2x = prevX + (x - prevX) / 2;
        final cp2y = lineY;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, x, lineY);
      }
    }

    // Glow effect (blur dihilangkan untuk optimasi memory dan bug transparency)
    final glowPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // Solid line
    final linePaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Data points (Dots)
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotStroke);
    }

    // X-Axis Labels (Days of week)
    final days = [
      'S',
      'S',
      'R',
      'K',
      'J',
      'S',
      'M',
    ]; // Sen, Sel, Rab, Kam, Jum, Sab, Min
    for (int i = 0; i < count; i++) {
      final x = i * (barWidth + spacing) + (barWidth / 2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 15),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, double width, double y, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double startX = 0.0;
    while (startX < width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ModernDualTrendPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// CONCENTRIC ACTIVITY RINGS (Apple Watch Style)
// ============================================================================

class AnimatedMacroDonut extends StatelessWidget {
  const AnimatedMacroDonut({
    super.key,
    required this.proteinPercent,
    required this.fatPercent,
    required this.carbsPercent,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double proteinPercent;
  final double fatPercent;
  final double carbsPercent;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCirc,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(160, 160),
          painter: _ConcentricRingsPainter(
            protein: proteinPercent,
            fat: fatPercent,
            carbs: carbsPercent,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            progress: value,
          ),
        );
      },
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  _ConcentricRingsPainter({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.primaryColor,
    required this.secondaryColor,
    required this.progress,
  });

  final double protein;
  final double fat;
  final double carbs;
  final Color primaryColor;
  final Color secondaryColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    const spacing = 4.0;

    // Radius for 3 rings
    final radius1 = (size.width / 2) - (strokeWidth / 2);
    final radius2 = radius1 - strokeWidth - spacing;
    final radius3 = radius2 - strokeWidth - spacing;

    void drawRing(double radius, double percent, Color baseColor) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Track
      final trackPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, trackPaint);

      if (percent <= 0) return;

      // Glow & Foreground
      final sweepAngle = (percent * 2 * math.pi) * progress;
      final startAngle = -math.pi / 2;

      final foregroundPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;

      // Fake shadow/glow at the cap (blur dihilangkan)
      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 4;

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, foregroundPaint);
    }

    // Max cap visual at 100% to prevent overdrawing rings
    drawRing(radius1, protein.clamp(0.0, 1.0), secondaryColor); // Protein
    drawRing(radius2, carbs.clamp(0.0, 1.0), primaryColor); // Carbs
    drawRing(radius3, fat.clamp(0.0, 1.0), Colors.amber); // Fat
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// MODERN CIRCULAR RADAR (Smooth Web with Gradient Fill)
// ============================================================================

class AnimatedNutrientRadar extends StatelessWidget {
  const AnimatedNutrientRadar({
    super.key,
    required this.values,
    required this.primaryColor,
    this.textColor = Colors.black54,
    this.size = 180,
  });

  final List<double> values;
  final Color primaryColor;
  final Color textColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutQuint,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: _ModernRadarPainter(
            values: values,
            primaryColor: primaryColor,
            textColor: textColor,
            progress: value,
          ),
        );
      },
    );
  }
}

class _ModernRadarPainter extends CustomPainter {
  _ModernRadarPainter({
    required this.values,
    required this.primaryColor,
    required this.textColor,
    required this.progress,
  });

  final List<double> values;
  final Color primaryColor;
  final Color textColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length != 6) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;

    // Circular Grid (Modern Apple style prefers circles over sharp polygons)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), gridPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - (math.pi / 2);
      final edge = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      _drawDashedLinePoints(canvas, center, edge, axisPaint);
    }

    // Draw Data Blob
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - (math.pi / 2);
      final r = radius * (values[i] * progress);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.6),
          primaryColor.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Vertex Dots and Text Labels
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStroke = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final labels = ['Kalori', 'Protein', 'Lemak', 'Karbo', 'Serat', 'Sodium'];

    for (int i = 0; i < 6; i++) {
      // Draw Dot
      canvas.drawCircle(points[i], 4, dotPaint);
      canvas.drawCircle(points[i], 4, dotStroke);

      // Draw Label
      final double angle = (i * math.pi / 3) - (math.pi / 2);
      // Position label slightly further out from the max radius
      final double labelRadius = radius + 15;
      final double lx = center.dx + labelRadius * math.cos(angle);
      final double ly = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      canvas.save();
      // Center the text on the calculated coordinate
      canvas.translate(lx - textPainter.width / 2, ly - textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  void _drawDashedLinePoints(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final distance = (p2 - p1).distance;
    final normalized = (p2 - p1) / distance;
    double current = 0;
    while (current < distance) {
      final start = p1 + normalized * current;
      final end = p1 + normalized * math.min(current + dashWidth, distance);
      canvas.drawLine(start, end, paint);
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ModernRadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
