import 'dart:async';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../shared/widgets/top_liquid_snackbar.dart';

class HydrationCelebrationOverlay extends StatelessWidget {
  const HydrationCelebrationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: const [
          _CelebrationCenterStack(),
          _CelebrationAccentBursts(),
          _RocketFlight(),
          _CelebrationNotification(),
        ],
      ),
    );
  }
}

class _CelebrationCenterStack extends StatefulWidget {
  const _CelebrationCenterStack();

  @override
  State<_CelebrationCenterStack> createState() =>
      _CelebrationCenterStackState();
}

class _CelebrationCenterStackState extends State<_CelebrationCenterStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final bell = 1.0 - ((t - 0.5).abs() * 2);
          final opacity = Curves.easeOut.transform(bell.clamp(0.0, 1.0));
          final scale = 0.85 + (0.25 * opacity);
          return Transform.scale(
            scale: scale,
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: const SizedBox(
          width: 340,
          height: 340,
          child: _DotLottieAsset(
            assetPath: 'assets/Congratulations.lottie',
            fallbackIcon: Icons.celebration_rounded,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CelebrationNotification extends StatelessWidget {
  const _CelebrationNotification();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: const TopLiquidSnackBarBanner(
            message: 'Selamat! Target minum hari ini tercapai',
            type: AppNotificationType.success,
            showCloseIcon: false,
          ),
        ),
      ),
    );
  }
}

class _CelebrationAccentBursts extends StatefulWidget {
  const _CelebrationAccentBursts();

  @override
  State<_CelebrationAccentBursts> createState() =>
      _CelebrationAccentBurstsState();
}

class _CelebrationAccentBurstsState extends State<_CelebrationAccentBursts> {
  final Random _random = Random();
  Timer? _switchTimer;
  int _activeAccentIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeAccentIndex = _random.nextInt(3);
    _switchTimer = Timer.periodic(const Duration(milliseconds: 760), (_) {
      if (!mounted) return;
      setState(() {
        var next = _random.nextInt(3);
        if (next == _activeAccentIndex) {
          next = (next + 1 + _random.nextInt(2)) % 3;
        }
        _activeAccentIndex = next;
      });
    });
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final topInset = MediaQuery.paddingOf(context).top;
        return Stack(
          children: [
            Positioned(
              left: 14,
              top: topInset + 62,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                opacity: _activeAccentIndex == 0 ? 0.8 : 0,
                child: Transform.rotate(
                  angle: -0.16,
                  child: const SizedBox(
                    width: 152,
                    height: 152,
                    child: _DotLottieAsset(
                      assetPath: 'assets/Congratulations.lottie',
                      fallbackIcon: Icons.auto_awesome_rounded,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: constraints.maxHeight * 0.2,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                opacity: _activeAccentIndex == 1 ? 0.74 : 0,
                child: Transform.rotate(
                  angle: 0.18,
                  child: const SizedBox(
                    width: 142,
                    height: 142,
                    child: _DotLottieAsset(
                      assetPath: 'assets/Congratulations.lottie',
                      fallbackIcon: Icons.celebration_rounded,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 72,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                opacity: _activeAccentIndex == 2 ? 0.66 : 0,
                child: Transform.rotate(
                  angle: -0.08,
                  child: const SizedBox(
                    width: 110,
                    height: 110,
                    child: _DotLottieAsset(
                      assetPath: 'assets/Congratulations.lottie',
                      fallbackIcon: Icons.stars_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RocketFlight extends StatelessWidget {
  const _RocketFlight();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final start = Offset(24, constraints.maxHeight * 0.58);
        final end = Offset(constraints.maxWidth + 260, -260);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2000),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            final dx = start.dx + (end.dx - start.dx) * t;
            final dy = start.dy + (end.dy - start.dy) * t;
            final tilt = -0.28 + (0.12 * (1 - t));
            return Stack(
              children: [
                Positioned(
                  left: dx,
                  top: dy,
                  child: Transform.rotate(
                    angle: tilt,
                    child: const SizedBox(
                      width: 220,
                      height: 220,
                      child: _DotLottieAsset(
                        assetPath: 'assets/Cat in a rocket.lottie',
                        fallbackIcon: Icons.rocket_launch_rounded,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DotLottieAsset extends StatefulWidget {
  const _DotLottieAsset({
    required this.assetPath,
    required this.fallbackIcon,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final BoxFit fit;

  @override
  State<_DotLottieAsset> createState() => _DotLottieAssetState();
}

class _DotLottieAssetState extends State<_DotLottieAsset> {
  static final Map<String, Future<Uint8List?>> _bytesCache =
      <String, Future<Uint8List?>>{};

  late final Future<Uint8List?> _animationBytesFuture;

  @override
  void initState() {
    super.initState();
    _animationBytesFuture = _bytesCache.putIfAbsent(
      widget.assetPath,
      () => _extractDotLottieJson(widget.assetPath),
    );
  }

  Future<Uint8List?> _extractDotLottieJson(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final zipBytes = data.buffer.asUint8List();
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: true);

    ArchiveFile? animationFile;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.toLowerCase();
      final isAnimationJson =
          name.startsWith('animations/') && name.endsWith('.json');
      if (isAnimationJson) {
        animationFile = file;
        break;
      }
    }
    if (animationFile == null) return null;

    final content = animationFile.content;
    if (content is List<int>) return Uint8List.fromList(content);
    if (content is Uint8List) return content;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _animationBytesFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return _FallbackPulseIcon(icon: widget.fallbackIcon);
        }
        return Lottie.memory(
          bytes,
          fit: widget.fit,
          repeat: true,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackPulseIcon(icon: widget.fallbackIcon);
          },
        );
      },
    );
  }
}

class _FallbackPulseIcon extends StatelessWidget {
  const _FallbackPulseIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.9, end: 1.05),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Icon(icon, size: 52, color: Colors.teal.shade400),
      ),
    );
  }
}
