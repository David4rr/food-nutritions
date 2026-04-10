import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AnimatedScanFrame extends StatefulWidget {
  const AnimatedScanFrame({super.key, this.size = 250});

  final double size;

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          width: _active ? 3 : 1.5,
          color: _active ? AppColors.accentStrong : AppColors.border,
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
                color: AppColors.accentStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
