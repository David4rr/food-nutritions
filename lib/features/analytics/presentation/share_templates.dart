import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/analytics_engine.dart';
import 'analytics_charts.dart';

import 'dart:typed_data';

enum ShareCardType { summary, trend, macro, radar }

abstract class ShareCardTemplate extends StatelessWidget {
  const ShareCardTemplate({
    super.key,
    required this.data,
    this.isTransparent = false,
    this.showWatermark = false,
    this.cardColor = Colors.white,
    this.bgImageBytes,
  });

  final AnalyticsData data;
  final bool isTransparent;
  final bool showWatermark;
  final Color cardColor;
  final Uint8List? bgImageBytes;

  bool get useWhiteText => cardColor == Colors.black || cardColor == Colors.transparent || isTransparent;

  Widget buildCard(BuildContext context, {required Widget child}) {
    // Apple Health style uses an off-white background
    final bgColor = isTransparent ? null : const Color(0xFFF2F2F7);

    return SizedBox(
      width: 1080,
      height: 1080,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          color: bgColor,
          alignment: Alignment.center,
          padding: EdgeInsets.all(isTransparent ? 16.0 : 64.0),
          child: child,
        ),
      ),
    );
  }

  Widget buildContainer({required Widget child}) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: isTransparent || cardColor == Colors.transparent
            ? BoxDecoration(
                image: bgImageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(bgImageBytes!),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: BorderRadius.circular(40),
              )
            : BoxDecoration(
                color: cardColor,
                image: bgImageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(bgImageBytes!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          cardColor.withValues(alpha: 0.5), // Tint the image with card color if they want color + image
                          BlendMode.darken,
                        ),
                      )
                    : null,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [],
              ),
        child: Column(
          children: [
            Expanded(
              child: SizedBox.expand(
                child: child,
              ),
            ),
            if (showWatermark) ...[
              const SizedBox(height: 12),
              Text(
                '@FoodNutritions',
                style: TextStyle(
                  color: useWhiteText ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 1. SUMMARY CARD
class SummaryShareCard extends ShareCardTemplate {
  const SummaryShareCard({
    super.key,
    required super.data,
    super.isTransparent,
    super.showWatermark,
    super.cardColor,
    super.bgImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = isPink
        ? const Color(0xFFE45BA5)
        : const Color(0xFF2FB8A4);

    return buildCard(
      context,
      child: buildContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Mingguan',
              style: TextStyle(
                fontSize: 48, // increased
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: useWhiteText ? Colors.white : Colors.black87,
              ),
            ),
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
                  color: primaryColor,
                  size: 32, // increased
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${data.calorieTrendPercent.abs().toStringAsFixed(1)}% vs minggu lalu',
                    style: TextStyle(
                      fontSize: 24, // increased
                      color: useWhiteText
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20, // increased
            color: useWhiteText ? Colors.white70 : Colors.grey.shade600,
            fontWeight: useWhiteText ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 40, // increased
            fontWeight: FontWeight.bold,
            color: useWhiteText ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// 2. TREND CARD
class TrendShareCard extends ShareCardTemplate {
  const TrendShareCard({
    super.key,
    required super.data,
    super.isTransparent,
    super.showWatermark,
    super.cardColor,
    super.bgImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = isPink
        ? const Color(0xFFE45BA5)
        : const Color(0xFF2FB8A4);
    final secondaryColor = isPink
        ? const Color(0xFF2FB8A4)
        : const Color(0xFFE45BA5);

    return buildCard(
      context,
      child: buildContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asupan Energi',
              style: TextStyle(
                fontSize: 48, // increased
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: useWhiteText ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kalori & Protein 7 Hari Terakhir',
              style: TextStyle(
                fontSize: 24, // increased
                color: useWhiteText ? Colors.white : Colors.grey.shade600,
                fontWeight: useWhiteText ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedDualTrendChart(
              calories: data.dailyEntries.map((e) => e.calories).toList(),
              protein: data.dailyEntries.map((e) => e.protein).toList(),
              targetCalories: data.targetCalories,
              targetProtein: data.targetProtein,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              height: 480, // INCREASED HEIGHT FOR SQUARE!
            ),
          ],
        ),
      ),
    );
  }
}

// 3. MACRO CARD
class MacroShareCard extends ShareCardTemplate {
  const MacroShareCard({
    super.key,
    required super.data,
    super.isTransparent,
    super.showWatermark,
    super.cardColor,
    super.bgImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = isPink
        ? const Color(0xFFE45BA5)
        : const Color(0xFF2FB8A4);
    final secondaryColor = isPink
        ? const Color(0xFF2FB8A4)
        : const Color(0xFFE45BA5);

    return buildCard(
      context,
      child: buildContainer(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribusi Makro',
                    style: TextStyle(
                      fontSize: 48, // increased
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: useWhiteText ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(
                    secondaryColor,
                    'Protein',
                    '${(data.macroProtein * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: 8),
                  _buildLegend(
                    primaryColor,
                    'Karbohidrat',
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
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 24, // increased
          height: 24, // increased
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 24, // increased
            color: useWhiteText ? Colors.white : Colors.black87,
            fontWeight: useWhiteText ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 24, // increased
            fontWeight: FontWeight.bold,
            color: useWhiteText ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// 4. RADAR CARD
class RadarShareCard extends ShareCardTemplate {
  const RadarShareCard({
    super.key,
    required super.data,
    super.isTransparent,
    super.showWatermark,
    super.cardColor,
    super.bgImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = isPink
        ? const Color(0xFFE45BA5)
        : const Color(0xFF2FB8A4);

    return buildCard(
      context,
      child: buildContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Keseimbangan Nutrisi',
              style: TextStyle(
                fontSize: 48, // increased
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: useWhiteText ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rasio Kualitas Asupan',
              style: TextStyle(
                fontSize: 24, // increased
                color: useWhiteText ? Colors.white : Colors.grey.shade600,
                fontWeight: useWhiteText ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: AnimatedNutrientRadar(
                values: [
                  (data.avgCalories / data.targetCalories).clamp(0.0, 1.0),
                  (data.avgProtein / data.targetProtein).clamp(0.0, 1.0),
                  (data.macroFat * 3).clamp(0.0, 1.0),
                  (data.macroCarbs * 2).clamp(0.0, 1.0),
                  0.7, // Serat Placeholder
                  0.5, // Sodium Placeholder
                ],
                primaryColor: primaryColor,
                textColor: useWhiteText ? Colors.white : Colors.black54,
                size: 440, // Increased size for the 874x874 square!
              ),
            ),
          ],
        ),
      ),
    );
  }
}
