import 'package:flutter/material.dart';

class _PathClipper extends CustomClipper<Path> {
  final Path path;
  _PathClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => true;
}

class ExpandingRoute<T> extends PageRouteBuilder<T> {
  ExpandingRoute({
    required Rect tileRect,
    required BorderRadiusGeometry tileRadius,
    required Widget page,
    Color? tileColor,
  }) : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: const Duration(milliseconds: 800), // Lebih pelan
          reverseTransitionDuration: const Duration(milliseconds: 800),
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // "konstan" berarti menggunakan animasi linear tanpa percepatan/perlambatan
            final expandCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.linear,
              reverseCurve: Curves.linear,
            );

            // Opacity juga dibuat konstan memudar perlahan dari awal sampai akhir
            final fadeCurve = CurvedAnimation(
              parent: animation,
              curve: Curves.linear,
              reverseCurve: Curves.linear,
            );

            final rectTween = RectTween(
              begin: tileRect,
              end: Rect.fromLTWH(
                0,
                0,
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height,
              ),
            );

            final borderRadiusTween = BorderRadiusTween(
              begin: tileRadius is BorderRadius
                  ? tileRadius
                  : BorderRadius.circular(16),
              end: BorderRadius.zero,
            );

            return AnimatedBuilder(
              animation: expandCurve,
              builder: (context, _) {
                final rect = rectTween.evaluate(expandCurve);
                final radius = borderRadiusTween.evaluate(expandCurve);

                if (rect == null) return const SizedBox.shrink();

                // Path dibuat persis mengikuti rect tile yang mengembang dan melengkung
                final path = Path()
                  ..addRRect(
                    RRect.fromRectAndCorners(
                      rect,
                      topLeft: radius?.topLeft ?? Radius.zero,
                      topRight: radius?.topRight ?? Radius.zero,
                      bottomLeft: radius?.bottomLeft ?? Radius.zero,
                      bottomRight: radius?.bottomRight ?? Radius.zero,
                    ),
                  );

                // ClipPath menjamin halaman Profile di dalamnya (yang full screen) 
                // akan ikut terpotong pinggirannya secara konsisten selama transisi
                return ClipPath(
                  clipper: _PathClipper(path),
                  child: Stack(
                    children: [
                      // Background solid (mencegah transparan saat page masih redup)
                      Container(
                        color: tileColor ?? Theme.of(context).colorScheme.surface,
                      ),
                      // Halaman aslinya
                      FadeTransition(
                        opacity: fadeCurve,
                        child: child,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
}

class ExpandingPageHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ExpandingPageHeader({super.key, required this.child});
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || route.animation == null) return child;
    return AnimatedBuilder(
      animation: route.animation!,
      builder: (context, child) {
        final val = route.animation!.value;
        final progress = ((val < 0.7) ? 0.0 : (val - 0.7) / 0.3).clamp(
          0.0,
          1.0,
        );
        return Transform.translate(
          offset: Offset(0, -preferredSize.height * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Size get preferredSize => child.preferredSize;
}

extension NavigatorX on BuildContext {
  Future<T?> expandTo<T>({
    required GlobalKey tileKey,
    required Widget page,
    BorderRadiusGeometry tileRadius = const BorderRadius.all(
      Radius.circular(16),
    ),
    Color? tileColor,
  }) {
    final renderBox = tileKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = offset & renderBox.size;

    return Navigator.of(this).push<T>(
      ExpandingRoute<T>(
        tileRect: rect,
        tileRadius: tileRadius,
        page: page,
        tileColor: tileColor,
      ),
    );
  }
}
