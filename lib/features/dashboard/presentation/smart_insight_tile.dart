import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../history/data/daily_nutrition_analytics_repository.dart';

class SmartInsightTile extends StatefulWidget {
  const SmartInsightTile({
    super.key,
    required this.width,
    required this.height,
    required this.targetCalories,
    required this.targetProtein,
    required this.todayCalories,
    required this.todayProtein,
    required this.dailyAnalytics,
    required this.lastScannedName,
  });

  final double width;
  final double height;
  final double? targetCalories;
  final double? targetProtein;
  final double todayCalories;
  final double todayProtein;
  final Map<String, DailyNutritionAggregate> dailyAnalytics;
  final String? lastScannedName;

  @override
  State<SmartInsightTile> createState() => _SmartInsightTileState();
}

class _SmartInsightTileState extends State<SmartInsightTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final color = visualMeta?.isPink == true
        ? const Color(0xFFAD1457)
        : const Color(0xFF2C3E50);
    final insight = _buildInsight();

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.05,
                end: 0.2,
              ).animate(_controller),
              child: Icon(insight.icon, size: 150, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(insight.icon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Asisten Pintar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  insight.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _InsightCandidate _buildInsight() {
    final candidates = <_InsightCandidate>[];

    final todayKey = _dateKey(DateTime.now());
    final todayAggregate =
        widget.dailyAnalytics[todayKey] ??
        DailyNutritionAggregate(
          dateKey: todayKey,
          calories: widget.todayCalories,
          protein: widget.todayProtein,
          scans: widget.lastScannedName == null ? 0 : 1,
        );

    final recent = widget.dailyAnalytics.values.toList(growable: false)
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final historyOnly = recent.where((e) => e.dateKey != todayKey).toList();
    final recent3 = historyOnly.length <= 3
        ? historyOnly
        : historyOnly.sublist(historyOnly.length - 3);

    if (widget.targetCalories != null &&
        widget.todayCalories > widget.targetCalories!) {
      final extra = widget.todayCalories - widget.targetCalories!;
      candidates.add(
        _InsightCandidate(
          score: 100,
          icon: Icons.warning_amber_rounded,
          text:
              'Kalori hari ini lebih ${extra.toStringAsFixed(0)} kkal dari target. Kurangi snack manis malam ini.',
        ),
      );
    }

    if (widget.targetProtein != null &&
        widget.todayProtein < widget.targetProtein!) {
      final left = widget.targetProtein! - widget.todayProtein;
      final urgentScore = left >= 20 ? 95 : 80;
      candidates.add(
        _InsightCandidate(
          score: urgentScore,
          icon: Icons.egg_alt_rounded,
          text:
              'Protein kurang ${left.toStringAsFixed(0)}g hari ini. Tambah telur, tempe, atau dada ayam di makan berikutnya.',
        ),
      );
    }

    if (recent3.isNotEmpty && widget.targetProtein != null) {
      final avgProtein =
          recent3.fold<double>(0, (sum, e) => sum + e.protein) / recent3.length;
      if (avgProtein < widget.targetProtein! * 0.75) {
        candidates.add(
          _InsightCandidate(
            score: 76,
            icon: Icons.trending_down_rounded,
            text:
                'Rata-rata protein 3 hari terakhir masih rendah. Coba targetkan sumber protein di tiap waktu makan.',
          ),
        );
      }
    }

    if (recent3.isNotEmpty && widget.targetCalories != null) {
      final avgCalories =
          recent3.fold<double>(0, (sum, e) => sum + e.calories) /
          recent3.length;
      if (avgCalories > widget.targetCalories! * 1.1) {
        candidates.add(
          _InsightCandidate(
            score: 72,
            icon: Icons.local_fire_department_rounded,
            text:
                'Tren 3 hari terakhir cenderung over kalori. Perbanyak serat dan minum air sebelum makan besar.',
          ),
        );
      }
    }

    final lowScanDays = recent3.where((e) => e.scans == 0).length;
    if (lowScanDays >= 2 && todayAggregate.scans == 0) {
      candidates.add(
        _InsightCandidate(
          score: 68,
          icon: Icons.qr_code_scanner_rounded,
          text:
              'Akhir-akhir ini kamu jarang scan. Scan 1-2 produk utama hari ini supaya insight lebih akurat.',
        ),
      );
    }

    if (widget.lastScannedName != null) {
      candidates.add(
        _InsightCandidate(
          score: 40,
          icon: Icons.info_outline_rounded,
          text:
              'Scan terakhir: ${widget.lastScannedName}. Lanjutkan tracking agar pola nutrisimu makin terlihat.',
        ),
      );
    }

    if (candidates.isEmpty) {
      return const _InsightCandidate(
        score: 10,
        icon: Icons.lightbulb_circle,
        text:
            'Mulai scan produk pertamamu hari ini untuk melihat insight yang lebih personal.',
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _InsightCandidate {
  const _InsightCandidate({
    required this.score,
    required this.icon,
    required this.text,
  });

  final int score;
  final IconData icon;
  final String text;
}
