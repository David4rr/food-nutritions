import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../history/presentation/history_provider.dart';
import '../domain/analytics_engine.dart';
import 'analytics_charts.dart';
import 'share_sheet.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_count.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return FutureBuilder<Box<dynamic>>(
      future: Hive.openBox<dynamic>('profile_target_box'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final box = snapshot.data!;
        final tCal = (box.get('target_calories') as num?)?.toDouble() ?? 2000.0;
        final tPro =
            (box.get('target_protein_min') as num?)?.toDouble() ?? 50.0;

        final data = AnalyticsEngine.compute(history.items, tCal, tPro);

        final palette = Theme.of(context).extension<DashboardTilePalette>();
        final mainColor = palette?.scan ?? Theme.of(context).primaryColor;
        final secondColor = palette?.profile ?? Theme.of(context).colorScheme.secondary;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                title: const Text('Analisis Nutrisi'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ShareSheet(data: data),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNativeCard(context: context,
                        title: 'Ringkasan Mingguan',
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetric(
                                    'Kalori Rata-rata',
                                    data.avgCalories,
                                    'kkal',
                                  ),
                                ),
                                Expanded(
                                  child: _buildMetric(
                                    'Protein Rata-rata',
                                    data.avgProtein,
                                    'g',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  data.calorieTrendPercent >= 0
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: mainColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${data.calorieTrendPercent.abs().toStringAsFixed(1)}% vs minggu lalu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNativeCard(context: context,
                        title: 'Asupan Energi',
                        subtitle: 'Kalori & Protein 7 Hari Terakhir',
                        child: AnimatedDualTrendChart(
                          calories: data.dailyEntries
                              .map((e) => e.calories)
                              .toList(),
                          protein: data.dailyEntries
                              .map((e) => e.protein)
                              .toList(),
                          targetCalories: data.targetCalories,
                          targetProtein: data.targetProtein,
                          primaryColor: mainColor,
                          secondaryColor: secondColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNativeCard(context: context,
                        title: 'Distribusi Makro',
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLegend(
                                    secondColor,
                                    'Protein',
                                    '${(data.macroProtein * 100).toStringAsFixed(1)}%',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLegend(
                                    mainColor,
                                    'Karbo',
                                    '${(data.macroCarbs * 100).toStringAsFixed(1)}%',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLegend(
                                    Colors.amber,
                                    'Lemak',
                                    '${(data.macroFat * 100).toStringAsFixed(1)}%',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: AnimatedMacroDonut(
                                  proteinPercent: data.macroProtein,
                                  fatPercent: data.macroFat,
                                  carbsPercent: data.macroCarbs,
                                  primaryColor: mainColor,
                                  secondaryColor: secondColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNativeCard(context: context,
                        title: 'Keseimbangan Nutrisi',
                        subtitle: 'Rasio Kualitas Asupan',
                        child: Center(
                          child: AnimatedNutrientRadar(
                            values: [
                              (data.avgCalories / data.targetCalories).clamp(
                                0.0,
                                1.0,
                              ),
                              (data.avgProtein / data.targetProtein).clamp(
                                0.0,
                                1.0,
                              ),
                              (data.macroFat * 3).clamp(0.0, 1.0),
                              (data.macroCarbs * 2).clamp(0.0, 1.0),
                              0.7,
                              0.5,
                            ],
                            primaryColor: mainColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Smart Insights at the bottom
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Insights',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...data.insights.map(
                              (insight) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '✦ ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFE45BA5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        insight,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNativeCard({
    required String title,
    required Widget child,
    String? subtitle,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        AnimatedCount(
          value: value,
          builder: (context, val) => Text(
            '${val.toStringAsFixed(0)} $suffix',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
