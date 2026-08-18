import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/animated_pressable.dart';

class HealthyGuardTile extends StatelessWidget {
  const HealthyGuardTile({
    super.key,
    required this.width,
    required this.height,
    required this.todaySugars,
    required this.todaySodium,
    required this.todaySaturatedFat,
    required this.color,
    this.onTap,
  });

  final double width;
  final double height;
  final double todaySugars;
  final double todaySodium;
  final double todaySaturatedFat;
  final Color color;
  final VoidCallback? onTap;

  static const double maxDailySugar = 50.0; // 50g per Kemenkes / WHO
  static const double maxDailySodium = 2000.0; // 2000mg per Kemenkes / WHO
  static const double maxDailySatFat = 20.0; // 20g per Kemenkes / WHO

  @override
  Widget build(BuildContext context) {
    final sugarRatio = (todaySugars / maxDailySugar).clamp(0.0, 1.0);
    final sodiumRatio = (todaySodium / maxDailySodium).clamp(0.0, 1.0);
    final satFatRatio = (todaySaturatedFat / maxDailySatFat).clamp(0.0, 1.0);

    final isSugarExceeded = todaySugars > maxDailySugar;
    final isSodiumExceeded = todaySodium > maxDailySodium;
    final isSatFatExceeded = todaySaturatedFat > maxDailySatFat;
    final isAnyExceeded = isSugarExceeded || isSodiumExceeded || isSatFatExceeded;

    final isSugarWarning = !isSugarExceeded && todaySugars > (maxDailySugar * 0.7);
    final isSodiumWarning = !isSodiumExceeded && todaySodium > (maxDailySodium * 0.7);
    final isSatFatWarning = !isSatFatExceeded && todaySaturatedFat > (maxDailySatFat * 0.7);
    final isAnyWarning = isSugarWarning || isSodiumWarning || isSatFatWarning;

    String statusText = 'Aman';
    Color statusBadgeColor = Colors.white.withValues(alpha: 0.22);
    if (isAnyExceeded) {
      statusText = 'Berlebih';
      statusBadgeColor = Colors.red.shade900.withValues(alpha: 0.45);
    } else if (isAnyWarning) {
      statusText = 'Waspada';
      statusBadgeColor = Colors.amber.shade900.withValues(alpha: 0.4);
    }

    final subtitle =
        'Gula ${todaySugars.toStringAsFixed(0)}g • Garam ${todaySodium.toStringAsFixed(0)}mg • Lemak ${todaySaturatedFat.toStringAsFixed(0)}g';

    return AnimatedPressable(
      onPressed: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Standard Background Watermark Icon (matching other tiles)
            Positioned(
              right: -16,
              top: -16,
              child: Icon(
                Icons.health_and_safety_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final clusterSize = (constraints.maxHeight * 0.56).clamp(140.0, 168.0);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Icon + Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBadgeColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Center: 3-Wheel Triangular Cluster (Enlarged Tiga Roda)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            builder: (context, animProgress, _) {
                              return SizedBox(
                                width: clusterSize,
                                height: clusterSize,
                                child: CustomPaint(
                                  painter: _MinimalTigaRodaPainter(
                                    sugarRatio: sugarRatio * animProgress,
                                    sodiumRatio: sodiumRatio * animProgress,
                                    satFatRatio: satFatRatio * animProgress,
                                    isSugarExceeded: isSugarExceeded,
                                    isSodiumExceeded: isSodiumExceeded,
                                    isSatFatExceeded: isSatFatExceeded,
                                    isSugarWarning: isSugarWarning,
                                    isSodiumWarning: isSodiumWarning,
                                    isSatFatWarning: isSatFatWarning,
                                    sugarText: '${todaySugars.toStringAsFixed(0)}g',
                                    sodiumText: '${todaySodium.toStringAsFixed(0)}mg',
                                    satFatText: '${todaySaturatedFat.toStringAsFixed(0)}g',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Bottom: Standard Title & Subtitle (matching other tiles)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Batas Sehat',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalTigaRodaPainter extends CustomPainter {
  const _MinimalTigaRodaPainter({
    required this.sugarRatio,
    required this.sodiumRatio,
    required this.satFatRatio,
    required this.isSugarExceeded,
    required this.isSodiumExceeded,
    required this.isSatFatExceeded,
    required this.isSugarWarning,
    required this.isSodiumWarning,
    required this.isSatFatWarning,
    required this.sugarText,
    required this.sodiumText,
    required this.satFatText,
  });

  final double sugarRatio;
  final double sodiumRatio;
  final double satFatRatio;
  final bool isSugarExceeded;
  final bool isSodiumExceeded;
  final bool isSatFatExceeded;
  final bool isSugarWarning;
  final bool isSodiumWarning;
  final bool isSatFatWarning;
  final String sugarText;
  final String sodiumText;
  final String satFatText;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Radius of each individual wheel (significantly enlarged for legibility)
    final wheelRadius = size.width * 0.31;
    const strokeWidth = 5.0;

    // Distance from center to triangle vertices
    final d = size.width * 0.22;

    // 1. Wheel 1 (Top - Gula)
    final centerTop = Offset(cx, cy - d * 0.85);

    // 2. Wheel 2 (Bottom Left - Garam)
    final centerBottomLeft = Offset(
      cx - d * math.cos(math.pi / 6),
      cy + d * math.sin(math.pi / 6) + 4,
    );

    // 3. Wheel 3 (Bottom Right - Lemak Jenuh)
    final centerBottomRight = Offset(
      cx + d * math.cos(math.pi / 6),
      cy + d * math.sin(math.pi / 6) + 4,
    );

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.18);

    // Draw 3 Background Tracks
    canvas.drawCircle(centerTop, wheelRadius, trackPaint);
    canvas.drawCircle(centerBottomLeft, wheelRadius, trackPaint);
    canvas.drawCircle(centerBottomRight, wheelRadius, trackPaint);

    // Draw 3 Progress Arcs
    _drawArc(
      canvas,
      centerTop,
      wheelRadius,
      sugarRatio,
      strokeWidth,
      isSugarExceeded
          ? Colors.red.shade300
          : (isSugarWarning ? Colors.amber.shade300 : Colors.white),
    );

    _drawArc(
      canvas,
      centerBottomLeft,
      wheelRadius,
      sodiumRatio,
      strokeWidth,
      isSodiumExceeded
          ? Colors.red.shade300
          : (isSodiumWarning ? Colors.amber.shade300 : Colors.white),
    );

    _drawArc(
      canvas,
      centerBottomRight,
      wheelRadius,
      satFatRatio,
      strokeWidth,
      isSatFatExceeded
          ? Colors.red.shade300
          : (isSatFatWarning ? Colors.amber.shade300 : Colors.white),
    );

    // Draw Minimalist Typography inside each wheel (enlarged & bold)
    _drawWheelContent(canvas, centerTop, 'Gula', sugarText);
    _drawWheelContent(canvas, centerBottomLeft, 'Garam', sodiumText);
    _drawWheelContent(canvas, centerBottomRight, 'Lemak', satFatText);
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double ratio,
    double strokeWidth,
    Color color,
  ) {
    if (ratio <= 0) return;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    const startAngle = -math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * ratio,
      false,
      progressPaint,
    );
  }

  void _drawWheelContent(
    Canvas canvas,
    Offset center,
    String label,
    String value,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: '$label\n',
      style: GoogleFonts.dmSans(
        color: Colors.white.withValues(alpha: 0.88),
        fontSize: 10.0,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
      children: [
        TextSpan(
          text: value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
      ],
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _MinimalTigaRodaPainter oldDelegate) {
    return oldDelegate.sugarRatio != sugarRatio ||
        oldDelegate.sodiumRatio != sodiumRatio ||
        oldDelegate.satFatRatio != satFatRatio ||
        oldDelegate.sugarText != sugarText ||
        oldDelegate.sodiumText != sodiumText ||
        oldDelegate.satFatText != satFatText;
  }
}
