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
         transitionDuration: const Duration(milliseconds: 400), // Lebih pelan
         reverseTransitionDuration: const Duration(milliseconds: 400),
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
                 : BorderRadius.circular(24),
             end: BorderRadius.zero,
           );

           // Keeps the corners rounded for a longer portion of the animation
           final radiusCurve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeInQuint,
           );

           return AnimatedBuilder(
             animation: expandCurve,
             builder: (context, _) {
               final rect = rectTween.evaluate(expandCurve);
               final radius = borderRadiusTween.evaluate(radiusCurve);

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
                       color:
                           tileColor ?? Theme.of(context).colorScheme.surface,
                     ),
                     // Halaman aslinya
                     FadeTransition(opacity: fadeCurve, child: child),
                   ],
                 ),
               );
             },
           );
         },
       );
}

extension NavigatorX on BuildContext {
  Future<T?> expandTo<T>({
    required GlobalKey tileKey,
    required Widget page,
    BorderRadiusGeometry tileRadius = const BorderRadius.all(
      Radius.circular(24), // Increased from 16 to 24
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
