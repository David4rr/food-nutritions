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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 10, // Ketebalan kaca/air
          blur: 2, // Sangat kecil agar jernih (clear glass), bukan frosted
          glassColor: Color(0x05FFFFFF),
          saturation: 1.2,
          lightIntensity: 3.5, // Cahaya kuat untuk efek pantulan basah/glossy
          ambientStrength: 0.25,
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Tint tipis berwarna sesuai tipe (merah/hijau/dll) agar mudah dikenali
                Positioned.fill(
                  child: Container(
                    color: palette.accent.withValues(alpha: 0.35),
                  ),
                ),
                // Efek pantulan cahaya (Specular Highlight) di atas permukaan kaca/air
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.15),
                          ],
                          stops: const [0.0, 0.25, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Konten teks dan ikon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        palette.icon,
                        color: Colors.white,
                        size: 24,
                        shadows: const [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            height: 1.3,
                            letterSpacing: 0.1,
                            // Shadow hitam kuat WAJIB ada di clear glass agar teks selalu bisa dibaca
                            // walau background kamera di belakangnya sangat terang/putih.
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showCloseIcon) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
