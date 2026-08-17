import 'package:flutter/material.dart';

class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    this.builder,
    this.style,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext context, double value)? builder;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        if (builder != null) {
          return builder!(context, val);
        }
        return Text(
          val.toStringAsFixed(val == val.roundToDouble() ? 0 : 1),
          style: style,
        );
      },
    );
  }
}
