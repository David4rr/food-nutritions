import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

enum AppVisualStyle { defaultStyle, pinkBloom }

@immutable
class AppVisualMeta extends ThemeExtension<AppVisualMeta> {
  const AppVisualMeta({required this.style});

  final AppVisualStyle style;

  bool get isPink => style == AppVisualStyle.pinkBloom;

  @override
  AppVisualMeta copyWith({AppVisualStyle? style}) {
    return AppVisualMeta(style: style ?? this.style);
  }

  @override
  AppVisualMeta lerp(covariant ThemeExtension<AppVisualMeta>? other, double t) {
    if (other is! AppVisualMeta) return this;
    return t < 0.5 ? this : other;
  }
}

@immutable
class DashboardTilePalette extends ThemeExtension<DashboardTilePalette> {
  const DashboardTilePalette({
    required this.scan,
    required this.profile,
    required this.history,
    required this.total,
    required this.targetCalories,
    required this.targetProtein,
    required this.profileCard,
  });

  final Color scan;
  final Color profile;
  final Color history;
  final Color total;
  final Color targetCalories;
  final Color targetProtein;
  final Color profileCard;

  @override
  DashboardTilePalette copyWith({
    Color? scan,
    Color? profile,
    Color? history,
    Color? total,
    Color? targetCalories,
    Color? targetProtein,
    Color? profileCard,
  }) {
    return DashboardTilePalette(
      scan: scan ?? this.scan,
      profile: profile ?? this.profile,
      history: history ?? this.history,
      total: total ?? this.total,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      profileCard: profileCard ?? this.profileCard,
    );
  }

  @override
  DashboardTilePalette lerp(
    covariant ThemeExtension<DashboardTilePalette>? other,
    double t,
  ) {
    if (other is! DashboardTilePalette) return this;
    return DashboardTilePalette(
      scan: Color.lerp(scan, other.scan, t) ?? scan,
      profile: Color.lerp(profile, other.profile, t) ?? profile,
      history: Color.lerp(history, other.history, t) ?? history,
      total: Color.lerp(total, other.total, t) ?? total,
      targetCalories:
          Color.lerp(targetCalories, other.targetCalories, t) ?? targetCalories,
      targetProtein:
          Color.lerp(targetProtein, other.targetProtein, t) ?? targetProtein,
      profileCard: Color.lerp(profileCard, other.profileCard, t) ?? profileCard,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({AppVisualStyle style = AppVisualStyle.defaultStyle}) {
    final isPink = style == AppVisualStyle.pinkBloom;
    final tilePalette = _tilePalette(style);
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isPink ? const Color(0xFFE45BA5) : AppColors.accent,
        surface: AppColors.surface,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SpringPageTransitionsBuilder(),
          TargetPlatform.iOS: SpringPageTransitionsBuilder(),
          TargetPlatform.macOS: SpringPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: ThemeData.light().textTheme.copyWith(
        displaySmall: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        tilePalette,
        AppVisualMeta(style: style),
      ],
    );
  }

  static DashboardTilePalette _tilePalette(AppVisualStyle style) {
    if (style == AppVisualStyle.pinkBloom) {
      return const DashboardTilePalette(
        scan: Color(0xFFF06292),
        profile: Color(0xFFEC407A),
        history: Color(0xFFF48FB1),
        total: Color(0xFFE91E63),
        targetCalories: Color(0xFFD81B60),
        targetProtein: Color(0xFFAD1457),
        profileCard: Color(0xFFC2185B),
      );
    }

    return const DashboardTilePalette(
      scan: Color(0xFF2FB8A4),
      profile: Color(0xFF5BA7FF),
      history: Color(0xFFF59E6D),
      total: Color(0xFF9B8AFB),
      targetCalories: Color(0xFFEF6C57),
      targetProtein: Color(0xFF00A8B5),
      profileCard: Color(0xFF3F51B5),
    );
  }
}

class SpringPageTransitionsBuilder extends PageTransitionsBuilder {
  const SpringPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) {
      return child;
    }

    final slideAnimation =
        Tween<Offset>(
          begin: const Offset(
            0.20,
            0,
          ), // Slide dari 20% sebelah kanan (tidak terlalu jauh)
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut, // Kurva khas Apple iOS
            reverseCurve: Curves.fastOutSlowIn,
          ),
        );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: fadeAnimation, child: child),
    );
  }
}
