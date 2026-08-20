import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/routes/expanding_route.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../history/presentation/daily_meal_tracker_page.dart';

class FoodGradeTile extends StatefulWidget {
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
  State<FoodGradeTile> createState() => _FoodGradeTileState();
}

class _FoodGradeTileState extends State<FoodGradeTile> {
  final _tileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    String grade = 'C';
    Color color = isPink ? const Color(0xFFEC407A) : const Color(0xFFEDB021);
    String message = 'Cukup baik';

    if (widget.calories == 0 && widget.protein == 0) {
      grade = '-';
      color = isPink ? const Color(0xFFF8BBD0) : const Color(0xFF9E9E9E);
      message = 'Belum ada data';
    } else if (widget.protein > widget.calories * 0.05) {
      grade = 'A';
      color = isPink ? const Color(0xFFC2185B) : const Color(0xFF009688);
      message = 'Sangat baik!';
    } else if (widget.protein > widget.calories * 0.03) {
      grade = 'B';
      color = isPink ? const Color(0xFFD81B60) : const Color(0xFF8BC34A);
      message = 'Pilihan bagus';
    } else if (widget.calories > 2000) {
      grade = 'E';
      color = isPink ? const Color(0xFF880E4F) : const Color(0xFFE53935);
      message = 'Kurangi kalori';
    }

    return AnimatedPressable(
      onPressed: () {
        context.expandTo(
          tileKey: _tileKey,
          page: const DailyMealTrackerPage(),
          tileColor: color,
          tileRadius: BorderRadius.circular(24),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        key: _tileKey,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const Spacer(),
                    Text(
                      'Grade $grade',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
