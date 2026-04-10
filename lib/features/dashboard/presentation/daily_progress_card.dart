import 'package:flutter/material.dart';

import '../domain/nutrition_target.dart';

class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.target,
    required this.todayCalories,
    required this.todayProtein,
  });

  final DailyTarget? target;
  final double todayCalories;
  final double todayProtein;

  @override
  Widget build(BuildContext context) {
    if (target == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: const Text(
          'Isi profil di bawah untuk menghitung target harian.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetroProgressTile(
          title: 'Target Kalori',
          icon: Icons.local_dining_rounded,
          current: todayCalories,
          target: target!.calories,
          unit: 'kkal',
          color: const Color(0xFFE91E63), // Pink material
        ),
        const SizedBox(height: 12),
        _MetroProgressTile(
          title: 'Target Protein',
          icon: Icons.fitness_center_rounded,
          current: todayProtein,
          target: target!.proteinMin,
          unit: 'g',
          color: const Color(0xFF00BCD4), // Light blue material
        ),
      ],
    );
  }
}

class _MetroProgressTile extends StatelessWidget {
  const _MetroProgressTile({
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String title;
  final IconData icon;
  final double current;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double percentage = target <= 0
        ? 0.0
        : (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Stack(
        children: [
          // Background graphic effect
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: percentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
