import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme/app_theme.dart';

class NutriScoreChip extends StatelessWidget {
  const NutriScoreChip({super.key, required this.score});

  final String? score;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final grade = (score ?? '').trim().toLowerCase();
    final hasGrade = RegExp(r'^[a-e]$').hasMatch(grade);
    final url = hasGrade
        ? 'https://static.openfoodfacts.org/images/attributes/dist/nutriscore-$grade.svg'
        : null;
    final note = _noteForGrade(grade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPink
              ? const [Color(0xFFF06292), Color(0xFFAD1457)]
              : const [Color(0xFF5BA7FF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPink ? const Color(0xFFE91E63) : const Color(0xFF5BA7FF))
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (url != null) ...[
                SizedBox(
                  height: 32,
                  child: SvgPicture.network(
                    url,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        _NutriFallbackBadge(score: score),
                  ),
                ),
              ] else ...[
                const SizedBox(
                  height: 32,
                  child: Center(child: _NutriFallbackBadge(score: null)),
                ),
              ],
              const SizedBox(width: 10),
              const Text(
                'Nutri-Score',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _noteForGrade(String grade) {
    switch (grade) {
      case 'a':
      case 'b':
        return 'Kualitas gizi baik';
      case 'c':
        return 'Kualitas gizi sedang';
      case 'd':
      case 'e':
        return 'Perlu dibatasi';
      default:
        return 'Indikator kualitas gizi';
    }
  }
}

class _NutriFallbackBadge extends StatelessWidget {
  const _NutriFallbackBadge({required this.score});

  final String? score;

  @override
  Widget build(BuildContext context) {
    final text = (score ?? 'N/A').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
