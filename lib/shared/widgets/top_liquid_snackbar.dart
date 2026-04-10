import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../app/theme/app_colors.dart';

enum AppNotificationType { info, success, warning, error }

class TopLiquidSnackBarBanner extends StatelessWidget {
  const TopLiquidSnackBarBanner({
    super.key,
    required this.message,
    this.type = AppNotificationType.info,
    this.showCloseIcon = true,
  });

  final String message;
  final AppNotificationType type;
  final bool showCloseIcon;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(type);

    return LiquidGlassLayer(
      settings: const LiquidGlassSettings(
        thickness: 14,
        blur: 6,
        glassColor: Color(0x12FFFFFF),
        saturation: 1.1,
        lightIntensity: 2.1,
        ambientStrength: 0.18,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 26),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x2AFFFFFF), Color(0x12FFFFFF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.05),
                        radius: 1.0,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.38, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      palette.icon,
                      color: palette.accent.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.6,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (showCloseIcon) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopLiquidSnackBar {
  TopLiquidSnackBar._();

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    _activeEntry?.remove();
    _activeEntry = OverlayEntry(
      builder: (_) => _TopLiquidSnackBarWidget(
        message: message,
        type: type,
        duration: duration,
        onClosed: () {
          _activeEntry?.remove();
          _activeEntry = null;
        },
      ),
    );

    overlay.insert(_activeEntry!);
  }
}

class _TopLiquidSnackBarWidget extends StatefulWidget {
  const _TopLiquidSnackBarWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onClosed,
  });

  final String message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_TopLiquidSnackBarWidget> createState() =>
      _TopLiquidSnackBarWidgetState();
}

class _TopLiquidSnackBarWidgetState extends State<_TopLiquidSnackBarWidget> {
  bool _visible = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });

    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    setState(() => _visible = false);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 10;

    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : const Offset(0, -0.35),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: TopLiquidSnackBarBanner(
                message: widget.message,
                type: widget.type,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

_SnackPalette _paletteFor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.success:
      return const _SnackPalette(
        icon: Icons.check_circle_rounded,
        accent: Color(0xFF1B8C63),
      );
    case AppNotificationType.warning:
      return const _SnackPalette(
        icon: Icons.warning_amber_rounded,
        accent: Color(0xFFB06A13),
      );
    case AppNotificationType.error:
      return const _SnackPalette(
        icon: Icons.error_rounded,
        accent: Color(0xFFB5362D),
      );
    case AppNotificationType.info:
      return const _SnackPalette(
        icon: Icons.info_rounded,
        accent: AppColors.accentStrong,
      );
  }
}

class _SnackPalette {
  const _SnackPalette({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}
