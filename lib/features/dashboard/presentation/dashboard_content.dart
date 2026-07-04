import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../history/data/daily_nutrition_analytics_repository.dart';
import '../../history/data/product_history.dart';
import '../../history/presentation/history_page.dart';
import '../../scanner/presentation/scanner_page.dart';
import '../../../shared/utils/navigator_extension.dart';
import 'dashboard_metro_tile.dart';
import 'dashboard_progress_tile.dart';
import 'food_grade_tile.dart';
import 'profile_page.dart';
import 'smart_insight_tile.dart';
import 'water_tracker_tile.dart';
import 'weekly_chart_tile.dart';
import 'calendar_trend_page.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
    required this.availableWidth,
    required this.spacing,
    required this.allItems,
    required this.todayItems,
    required this.todayCalories,
    required this.todayProtein,
    required this.weeklyCalories,
    required this.dailyAnalytics,
    required this.target,
    required this.profileBox,
    this.onHydrationCelebrate,
  });

  final double availableWidth;
  final double spacing;
  final List<ProductHistory> allItems;
  final List<ProductHistory> todayItems;
  final double todayCalories;
  final double todayProtein;
  final Map<String, double> weeklyCalories;
  final Map<String, DailyNutritionAggregate> dailyAnalytics;
  final DashboardTargetData? target;
  final dynamic profileBox;
  final VoidCallback? onHydrationCelebrate;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<DashboardTilePalette>() ??
        const DashboardTilePalette(
          scan: Color(0xFF2FB8A4),
          profile: Color(0xFF5BA7FF),
          history: Color(0xFFF59E6D),
          total: Color(0xFF9B8AFB),
          targetCalories: Color(0xFFEF6C57),
          targetProtein: Color(0xFF00A8B5),
          profileCard: Color(0xFF3F51B5),
        );
    final crossAxisCount = availableWidth > 600 ? 4 : 2;
    final baseWidth =
        (availableWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
    final baseHeight = 140.0;
    final blockWidth = baseWidth * 2 + spacing;
    final doubleHeight = baseHeight * 2 + spacing;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: Wrap(
        key: ValueKey(target == null ? 'no-target' : 'with-target'),
        spacing: spacing,
        runSpacing: spacing,
        children: [
          // BARIS 1: Scan (Besar) + Profil/Riwayat (Kecil) - SELALU ADA
          SizedBox(
            width: blockWidth,
            child: Row(
              children: [
                DashboardMetroTile(
                  width: baseWidth,
                  height: doubleHeight,
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan\nProduk',
                  subtitle: 'Baca barcode untuk nutrisi',
                  color: palette.scan,
                  onTap: () => context.pushRoute(const ScannerPage()),
                  large: true,
                ),
                SizedBox(width: spacing),
                SizedBox(
                  width: baseWidth,
                  height: doubleHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DashboardMetroTile(
                        width: baseWidth,
                        height: baseHeight,
                        icon: Icons.person_rounded,
                        title: 'Profil',
                        subtitle: 'Atur target',
                        color: palette.profile,
                        onTap: () => context.pushRoute(const ProfilePage()),
                      ),
                      DashboardMetroTile(
                        width: baseWidth,
                        height: baseHeight,
                        icon: Icons.history_rounded,
                        title: 'Riwayat',
                        subtitle: '${todayItems.length} scan',
                        color: palette.history,
                        onTap: () => context.pushRoute(const HistoryPage()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // JIKA TARGET ADA: Tampilkan Water & Food Grade di baris tengah (Posisi Semula)
          if (target != null)
            SizedBox(
              width: blockWidth,
              child: Row(
                children: [
                  HydrationTrackerTile(
                    width: baseWidth,
                    height: baseHeight,
                    profileBox: profileBox,
                    onCelebrate: onHydrationCelebrate,
                  ),
                  SizedBox(width: spacing),
                  FoodGradeTile(
                    width: baseWidth,
                    height: baseHeight,
                    calories: todayCalories,
                    protein: todayProtein,
                  ),
                ],
              ),
            ),

          // BARIS DINAMIS: Samping Total Kkal (Besar)
          SizedBox(
            width: blockWidth,
            child: Row(
              children: [
                SizedBox(
                  width: baseWidth,
                  height: doubleHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (target != null) ...[
                        // Jika ada target, tampilkan Progress Tiles di sini
                        DashboardProgressTile(
                          width: baseWidth,
                          height: baseHeight,
                          icon: Icons.local_fire_department_rounded,
                          label: 'Target Kalori',
                          current: todayCalories,
                          target: target!.calories,
                          unit: 'kkal',
                          color: palette.targetCalories,
                        ),
                        DashboardProgressTile(
                          width: baseWidth,
                          height: baseHeight,
                          icon: Icons.egg_alt_rounded,
                          label: 'Target Protein',
                          current: todayProtein,
                          target: target!.protein,
                          unit: 'g',
                          color: palette.targetProtein,
                        ),
                      ] else ...[
                        // Jika target KOSONG, pindahkan Water & Food Grade ke sini untuk mengisi slot
                        HydrationTrackerTile(
                          width: baseWidth,
                          height: baseHeight,
                          profileBox: profileBox,
                          onCelebrate: onHydrationCelebrate,
                        ),
                        FoodGradeTile(
                          width: baseWidth,
                          height: baseHeight,
                          calories: todayCalories,
                          protein: todayProtein,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: spacing),
                DashboardMetroTile(
                  width: baseWidth,
                  height: doubleHeight,
                  icon: Icons.local_fire_department_outlined,
                  title: '${todayCalories.toStringAsFixed(0)}\nkkal',
                  subtitle: 'Total asupan scan',
                  color: palette.total,
                  large: true,
                  onTap: () {
                    context.pushRoute(CalendarTrendPage(targetCalories: target?.calories ?? 2000.0));
                  },
                ),
              ],
            ),
          ),

          WeeklyChartTile(
            width: blockWidth,
            height: baseHeight * 1.2,
            weeklyCalories: weeklyCalories,
            targetCalories: target?.calories ?? 2000.0,
          ),
          SmartInsightTile(
            width: blockWidth,
            height: baseHeight,
            targetCalories: target?.calories,
            targetProtein: target?.protein,
            todayCalories: todayCalories,
            todayProtein: todayProtein,
            dailyAnalytics: dailyAnalytics,
            lastScannedName: todayItems.isNotEmpty
                ? todayItems.last.name
                : null,
          ),
        ],
      ),
    );
  }
}

class DashboardTargetData {
  const DashboardTargetData({required this.calories, required this.protein});

  final double calories;
  final double protein;
}
