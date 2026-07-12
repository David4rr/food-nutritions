import 'dart:ui';
import 'package:flutter/material.dart';

// ponytail: Minimum viable expanding page route.
class ExpandingPageRoute<T> extends PageRouteBuilder<T> {
  ExpandingPageRoute({
    required Rect tileRect,
    required BorderRadius tileBorderRadius,
    required Widget page,
    Color? tileColor,
  }) : super(
         pageBuilder: (_, _, _) => page,
         transitionDuration: const Duration(milliseconds: 900),
         reverseTransitionDuration: const Duration(milliseconds: 800),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return AnimatedBuilder(
             animation: animation,
             builder: (context, child) {
               final size = MediaQuery.of(context).size;

               // Phase 1: Tile Expands (0% -> 70% of the duration)
               final expandValue = CurvedAnimation(
                 parent: animation,
                 curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
               ).value;

               // Phase 2: Page Fades In (70% -> 100% of the duration)
               final fadeInValue = CurvedAnimation(
                 parent: animation,
                 curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
               ).value;
               // Phase 3: Border Radius fades out (50% -> 70% of the duration)
               // This keeps the tile fully rounded for the vast majority of the flight,
               // and only sharpens it to 0 right before it hits the edges of the screen (at 70%).
               final borderRadiusValue = CurvedAnimation(
                 parent: animation,
                 curve: const Interval(0.5, 0.7, curve: Curves.easeIn),
               ).value;

               // The expanding background tile
               final tileBackground = Positioned(
                 left: lerpDouble(tileRect.left, 0, expandValue),
                 top: lerpDouble(tileRect.top, 0, expandValue),
                 width: lerpDouble(tileRect.width, size.width, expandValue),
                 height: lerpDouble(tileRect.height, size.height, expandValue),
                 child: DecoratedBox(
                   decoration: BoxDecoration(
                     color: tileColor ?? Colors.transparent,
                     borderRadius: BorderRadius.lerp(
                       tileBorderRadius,
                       BorderRadius.zero,
                       borderRadiusValue,
                     )!,
                   ),
                 ),
               );

               return Stack(
                 children: [
                   tileBackground,
                   Opacity(opacity: fadeInValue, child: child),
                 ],
               );
             },
             child: child,
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
    BorderRadius tileRadius = const BorderRadius.all(Radius.circular(16)),
    Color? tileColor,
  }) {
    final renderBox = tileKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final rect = offset & renderBox.size;

    return Navigator.of(this).push<T>(
      ExpandingPageRoute<T>(
        tileRect: rect,
        tileBorderRadius: tileRadius,
        page: page,
        tileColor: tileColor,
      ),
    );
  }
}
