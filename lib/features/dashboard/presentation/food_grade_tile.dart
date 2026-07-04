import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';

class FoodGradeTile extends StatelessWidget {
  const FoodGradeTile({
    super.key,
    required this.width,
    required this.height,
    required this.calories,
    required this.protein,
  });

  final double width;
  final double height;
  final double calories;
  final double protein;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    String grade = 'C';
    Color color = isPink ? const Color(0xFFEC407A) : const Color(0xFFEDB021);
    String message = 'Cukup baik';

    if (calories == 0 && protein == 0) {
      grade = '-';
      color = isPink ? const Color(0xFFF8BBD0) : const Color(0xFF9E9E9E);
      message = 'Belum ada data';
    } else if (protein > calories * 0.05) {
      grade = 'A';
      color = isPink ? const Color(0xFFC2185B) : const Color(0xFF009688);
      message = 'Sangat baik!';
    } else if (protein > calories * 0.03) {
      grade = 'B';
      color = isPink ? const Color(0xFFD81B60) : const Color(0xFF8BC34A);
      message = 'Pilihan bagus';
    } else if (calories > 2000) {
      grade = 'E';
      color = isPink ? const Color(0xFF880E4F) : const Color(0xFFE53935);
      message = 'Kurangi kalori';
    }

    return AnimatedPressable(
      onPressed: () {},
      child: Container(
        width: width,
        height: height,
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
              right: -10,
              top: -10,
              child: Text(
                grade,
                style: TextStyle(
                  fontSize: 100,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const Spacer(),
                    Text(
                      'Grade $grade',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
