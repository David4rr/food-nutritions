import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AnimatedScanFrame extends StatefulWidget {
  const AnimatedScanFrame({
    super.key,
    this.size = 250,
    this.width,
    this.height,
    this.isOcrMode = false,
    this.color,
  });

  final double size;
  final double? width;
  final double? height;
  final bool isOcrMode;
  final Color? color;

  @override
  State<AnimatedScanFrame> createState() => _AnimatedScanFrameState();
}

class _AnimatedScanFrameState extends State<AnimatedScanFrame> {
  bool _active = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) {
        setState(() {
          _active = !_active;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final accentColor = widget.color ?? palette?.scan ?? Theme.of(context).primaryColor;

    final targetWidth = widget.width ?? widget.size;
    final targetHeight = widget.height ?? widget.size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      width: targetWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.isOcrMode ? 20 : 28),
        border: Border.all(
          width: _active ? 2.5 : 1.5,
          color: _active ? accentColor : Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Stack(
        children: [
          // Scanning laser line
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            top: _active ? targetHeight - 32 : 12,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 2.5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            ),
          ),

          // OCR Mode corner indicators
          if (widget.isOcrMode) ...[
            Positioned(
              top: 10,
              left: 10,
              child: Icon(Icons.document_scanner_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Text(
                'TABEL GIZI',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
