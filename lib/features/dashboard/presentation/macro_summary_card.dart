import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/nutrition_target.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({super.key, required this.target});

  final DailyTarget target;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final cardColor = palette?.targetProtein ?? const Color(0xFF673AB7);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
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
            child: Icon(
              Icons.flag_circle_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Tujuan Akhir Harian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MacroLine(
                  label: 'Kalori',
                  value: '${target.calories.toStringAsFixed(0)} kkal',
                ),
                const Divider(color: Colors.white24, height: 20),
                _MacroLine(
                  label: 'Karbo',
                  value:
                      '${target.carbsMin.toStringAsFixed(0)} - ${target.carbsMax.toStringAsFixed(0)} g',
                ),
                _MacroLine(
                  label: 'Pro',
                  value:
                      '${target.proteinMin.toStringAsFixed(0)} - ${target.proteinMax.toStringAsFixed(0)} g',
                ),
                _MacroLine(
                  label: 'Lemak',
                  value:
                      '${target.fatMin.toStringAsFixed(0)} - ${target.fatMax.toStringAsFixed(0)} g',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  const _MacroLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
