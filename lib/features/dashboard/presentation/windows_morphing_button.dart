import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dashboard_quick_hub_sheet.dart';

class WindowsMorphingButton extends StatefulWidget {
  const WindowsMorphingButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  State<WindowsMorphingButton> createState() => _WindowsMorphingButtonState();
}

class _WindowsMorphingButtonState extends State<WindowsMorphingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Animation<double> get _scaleAnimation => _controller.drive(
        Tween<double>(begin: 1.0, end: 0.84).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      );

  Animation<double> get _rotationAnimation => _controller.drive(
        Tween<double>(begin: 0.0, end: math.pi / 4).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
      );

  Animation<double> get _morphAnimation => _controller.drive(
        Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    await _controller.forward();
    if (!mounted) return;
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      DashboardQuickHubSheet.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;

    return Tooltip(
      message: 'Menu & Tampilan',
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0, left: 4.0),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            onTap: _handleTap,
            highlightShape: BoxShape.circle,
            radius: 24,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _scaleAnimation.value.clamp(0.5, 1.5),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: CustomPaint(
                          size: const Size(22, 22),
                          painter: _WindowsMorphPainter(
                            progress: _morphAnimation.value.clamp(0.0, 1.0),
                            color: iconColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter yang menggambar 4 tile Windows dan me-morphing bentuknya
/// dari 4 bujur sangkar (grid) menjadi 4 lingkaran/kapsul dengan jarak dinamis saat ditekan.
class _WindowsMorphPainter extends CustomPainter {
  _WindowsMorphPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final safeProgress = progress.clamp(0.0, 1.0);
    // Jarak (gap) antar tile membesar saat animasi morphing berjalan
    final gap = (2.5 + (3.0 * safeProgress)).clamp(0.0, size.width - 2);
    final tileSize = math.max(1.0, (size.width - gap) / 2);

    // Radius sudut: dari 2.5 (squircle) me-morph menjadi bulat penuh (tileSize / 2)
    final targetRadius = tileSize / 2;
    final radius = math.max(0.0, 2.5 + ((targetRadius - 2.5) * safeProgress));

    final lefts = [0.0, tileSize + gap];
    final tops = [0.0, tileSize + gap];

    for (final left in lefts) {
      for (final top in tops) {
        final rect = Rect.fromLTWH(left, top, tileSize, tileSize);
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(radius),
        );
        canvas.drawRRect(rrect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsMorphPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
