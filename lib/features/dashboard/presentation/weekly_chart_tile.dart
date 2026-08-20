import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';

class WeeklyChartTile extends StatelessWidget {
  const WeeklyChartTile({
    super.key,
    required this.width,
    required this.height,
    required this.weeklyCalories,
    required this.targetCalories,
    this.onTap,
  });

  final double width;
  final double height;
  final double targetCalories;
  final Map<String, double> weeklyCalories;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final startColor = isPink
        ? const Color(0xFFF06292)
        : const Color(0xFF8E44AD);
    final endColor = isPink ? const Color(0xFFAD1457) : const Color(0xFF6D2C91);
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );

    final dailyCalories = <String, double>{
      for (final day in last7Days)
        _dateKey(day): weeklyCalories[_dateKey(day)] ?? 0,
    };

    final maxCal = dailyCalories.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return AnimatedPressable(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: endColor.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tren Mingguan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: last7Days.map((day) {
                    final cal = dailyCalories[_dateKey(day)] ?? 0;
                    final ratio = maxCal == 0
                        ? 0.0
                        : (cal / maxCal).clamp(0.0, 1.0);
                    return Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (cal > 0)
                              Text(
                                cal.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: 40 * ratio + 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                'Sen',
                                'Sel',
                                'Rab',
                                'Kam',
                                'Jum',
                                'Sab',
                                'Min',
                              ][day.weekday - 1],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
