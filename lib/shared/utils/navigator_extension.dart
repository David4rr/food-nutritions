import 'package:flutter/material.dart';

extension NavigatorX on BuildContext {
  Future<T?> pushRoute<T>(Widget page) {
    return Navigator.of(this).push(_SpringPageRoute<T>(page: page));
  }

  Future<T?> pushReplacementRoute<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement(_SpringPageRoute<T>(page: page));
  }
}

class _SpringPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  _SpringPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation =
              Tween<Offset>(
                begin: const Offset(0.20, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastEaseInToSlowEaseOut,
                  reverseCurve: Curves.fastOutSlowIn,
                ),
              );

          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
      );
}
