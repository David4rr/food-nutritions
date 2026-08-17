import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AnimatedScanFrame extends StatefulWidget {
  const AnimatedScanFrame({super.key, this.size = 250, this.color});

  final double size;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          width: _active ? 3 : 1.5,
          color: _active ? accentColor : Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            top: _active ? widget.size - 40 : 12,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
