import 'package:flutter/material.dart';

class StaggeredAnimatedTile extends StatefulWidget {
  const StaggeredAnimatedTile({
    super.key,
    required this.child,
    required this.index,
    this.delayMs = 60,
  });

  final Widget child;
  final int index;
  final int delayMs;

  @override
  State<StaggeredAnimatedTile> createState() => _StaggeredAnimatedTileState();
}

class _StaggeredAnimatedTileState extends State<StaggeredAnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Sedikit lebih lambat agar spring terasa
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Apple-like spring (membal)
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Delay sesuai index
    if (widget.index > 0 && widget.delayMs > 0) {
      await Future.delayed(Duration(milliseconds: widget.index * widget.delayMs));
    }
    if (mounted) {
      setState(() => _isStarted = true);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      // Menjaga agar dimensi (layout) tetap ada meski belum terlihat
      return Opacity(
        opacity: 0.0,
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        // Fade in sedikit lebih cepat dari skala
        final opacity = (value * 1.5).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, 30.0 * (1.0 - value))
              ..scale(0.92 + (0.08 * value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
