import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../history/presentation/history_provider.dart';
import 'dashboard_content.dart';
import 'dashboard_idle_cat_overlay.dart';
import 'hydration_celebration_dialog.dart';
import 'windows_morphing_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _profileBoxName = 'profile_target_box';
  static const _hydrationOverlayDuration = Duration(milliseconds: 5500);
  static const _idleCatDelay = Duration(seconds: 15);
  late final Future<Box<dynamic>> _profileBoxFuture;
  Timer? _overlayTimer;
  Timer? _idleTimer;
  bool _showHydrationOverlay = false;
  bool _showIdleCatOverlay = false;

  @override
  void initState() {
    super.initState();
    _profileBoxFuture = _openProfileBox();
    _resetIdleTimer();
  }

  Future<Box<dynamic>> _openProfileBox() async {
    if (Hive.isBoxOpen(_profileBoxName)) {
      return Hive.box<dynamic>(_profileBoxName);
    }
    return Hive.openBox<dynamic>(_profileBoxName);
  }

  DashboardTargetData? _readTarget(Box<dynamic> box) {
    final calories = (box.get('target_calories') as num?)?.toDouble();
    final proteinMin = (box.get('target_protein_min') as num?)?.toDouble();
    final carbsMin = (box.get('target_carbs_min') as num?)?.toDouble();
    final fatMin = (box.get('target_fat_min') as num?)?.toDouble();
    if (calories == null) return null;
    return DashboardTargetData(
      calories: calories,
      protein: proteinMin ?? 0,
      carbs: carbsMin ?? 0,
      fat: fatMin ?? 0,
    );
  }

  void _onHydrationCelebrate() {
    _onUserActivity();
    _overlayTimer?.cancel();
    if (mounted) {
      setState(() => _showHydrationOverlay = true);
    }
    _overlayTimer = Timer(_hydrationOverlayDuration, () {
      if (!mounted) return;
      setState(() => _showHydrationOverlay = false);
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleCatDelay, () {
      if (!mounted || _showHydrationOverlay || _showIdleCatOverlay) return;
      setState(() => _showIdleCatOverlay = true);
    });
  }

  void _onUserActivity() {
    _idleTimer?.cancel();
    if (_showIdleCatOverlay && mounted) {
      setState(() => _showIdleCatOverlay = false);
    }
    _resetIdleTimer();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final todayItems = history.items
        .where((item) {
          final now = DateTime.now();
          final date = item.scanDate;
          return now.year == date.year &&
              now.month == date.month &&
              now.day == date.day;
        })
        .toList(growable: false);

    final todayMeals = history.todayMeals;
    final todayCalories = todayMeals.fold<double>(0, (sum, m) => sum + m.calories);
    final todayProtein = todayMeals.fold<double>(0, (sum, m) => sum + m.protein);
    final todayCarbs = todayMeals.fold<double>(0, (sum, m) => sum + m.carbs);
    final todayFat = todayMeals.fold<double>(0, (sum, m) => sum + m.fat);
    final todaySugars = todayMeals.fold<double>(0, (sum, m) => sum + m.sugars);
    final todaySodium = todayMeals.fold<double>(0, (sum, m) => sum + m.sodium);
    final todaySaturatedFat = todayMeals.fold<double>(0, (sum, m) => sum + m.saturatedFat);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _onUserActivity(),
        onPointerSignal: (_) => _onUserActivity(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification ||
                notification is UserScrollNotification) {
              _onUserActivity();
            }
            return false;
          },
          child: Stack(
            children: [
              FutureBuilder<Box<dynamic>>(
                future: _profileBoxFuture,
                builder: (context, snapshot) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeInOutCubic,
                              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                        title: const Text('Dashboard Nutrisi'),
                        actions: const [
                          WindowsMorphingButton(),
                        ],
                      ),
                      if (!snapshot.hasData)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        SliverToBoxAdapter(
                          child: ValueListenableBuilder<Box<dynamic>>(
                            valueListenable: snapshot.data!.listenable(
                              keys: const [
                                'target_calories',
                                'target_protein_min',
                                'target_carbs_min',
                                'target_fat_min',
                              ],
                            ),
                            builder: (context, value, _) {
                              final target = _readTarget(value);
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: DashboardContent(
                                      availableWidth: constraints.maxWidth - 32,
                                      spacing: 12,
                                      allItems: history.items,
                                      todayItems: todayItems,
                                      todayCalories: todayCalories,
                                      todayProtein: todayProtein,
                                      todayCarbs: todayCarbs,
                                      todayFat: todayFat,
                                      todaySugars: todaySugars,
                                      todaySodium: todaySodium,
                                      todaySaturatedFat: todaySaturatedFat,
                                      weeklyCalories: history.weeklyCalories,
                                      dailyAnalytics: history.dailyAnalytics,
                                      target: target,
                                      profileBox: value,
                                      onHydrationCelebrate: _onHydrationCelebrate,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showIdleCatOverlay
                    ? const DashboardIdleCatOverlay(
                        key: ValueKey('idle-cat-overlay'),
                      )
                    : const SizedBox.shrink(key: ValueKey('idle-cat-empty')),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showHydrationOverlay
                    ? const HydrationCelebrationOverlay(
                        key: ValueKey('hydration-overlay'),
                      )
                    : const SizedBox.shrink(key: ValueKey('hydration-empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
