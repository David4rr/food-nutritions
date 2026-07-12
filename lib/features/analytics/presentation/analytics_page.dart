import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../history/presentation/history_provider.dart';
import '../domain/analytics_engine.dart';
import 'analytics_charts.dart';
import 'share_sheet.dart';
import '../../../shared/routes/expanding_route.dart';
import '../../../app/theme/app_theme.dart';

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

        final visualMeta = Theme.of(context).extension<AppVisualMeta>();
        final isPink = visualMeta?.isPink ?? false;
        final startColor = isPink
            ? const Color(0xFFF06292)
            : const Color(0xFF8E44AD);

        return Scaffold(
          backgroundColor: startColor,
          appBar: ExpandingPageHeader(
            child: AppBar(
              backgroundColor: startColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Analisis Nutrisi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          ),
          body: Container(
            color: const Color(0xFFF2F2F7),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildNativeCard(
                  title: 'Ringkasan Mingguan',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(
                              'Kalori Rata-rata',
                              '${data.avgCalories.toStringAsFixed(0)} kkal',
                            ),
                          ),
                          Expanded(
                            child: _buildMetric(
                              'Protein Rata-rata',
                              '${data.avgProtein.toStringAsFixed(0)} g',
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
                            color: Theme.of(context).primaryColor,
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

                _buildNativeCard(
                  title: 'Asupan Energi',
                  subtitle: 'Kalori & Protein 7 Hari Terakhir',
                  child: AnimatedDualTrendChart(
                    calories: data.dailyEntries.map((e) => e.calories).toList(),
                    protein: data.dailyEntries.map((e) => e.protein).toList(),
                    targetCalories: data.targetCalories,
                    targetProtein: data.targetProtein,
                    primaryColor: Theme.of(context).primaryColor,
                    secondaryColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 16),

                _buildNativeCard(
                  title: 'Distribusi Makro',
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegend(
                              Theme.of(context).colorScheme.secondary,
                              'Protein',
                              '${(data.macroProtein * 100).toStringAsFixed(1)}%',
                            ),
                            const SizedBox(height: 8),
                            _buildLegend(
                              Theme.of(context).primaryColor,
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
                            primaryColor: Theme.of(context).primaryColor,
                            secondaryColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildNativeCard(
                  title: 'Keseimbangan Nutrisi',
                  subtitle: 'Rasio Kualitas Asupan',
                  child: Center(
                    child: AnimatedNutrientRadar(
                      values: [
                        (data.avgCalories / data.targetCalories).clamp(
                          0.0,
                          1.0,
                        ),
                        (data.avgProtein / data.targetProtein).clamp(0.0, 1.0),
                        (data.macroFat * 3).clamp(0.0, 1.0),
                        (data.macroCarbs * 2).clamp(0.0, 1.0),
                        0.7,
                        0.5,
                      ],
                      primaryColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Smart Insights at the bottom
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildNativeCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
