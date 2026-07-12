import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.child, this.isLoading = true});

  final Widget child;
  final bool isLoading;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.isLoading
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: const Alignment(-1.0, -0.3),
                      end: const Alignment(1.0, 0.3),
                      stops: const [0.4, 0.5, 0.6],
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.05),
                      ],
                      transform: _SlidingGradientTransform(
                        slidePercent: _controller.value,
                      ),
                    ).createShader(bounds);
                  },
                  child: child,
                );
              },
              child: widget.child,
            )
          : widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0.0,
      0.0,
    );
  }
}

class SkeletonTile extends StatelessWidget {
  const SkeletonTile({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 16.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonProductDetail extends StatelessWidget {
  const SkeletonProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 150, height: 24, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 32,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
