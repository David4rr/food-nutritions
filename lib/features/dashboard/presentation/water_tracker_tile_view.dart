import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_count.dart';

class WaterTrackerTileView extends StatelessWidget {
  const WaterTrackerTileView({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.glasses,
    required this.dailyMl,
    required this.targetMl,
    required this.percentText,
    required this.progressValue,
    required this.animation,
    required this.onTap,
  });

  final double width;
  final double height;
  final Color color;
  final int glasses;
  final int dailyMl;
  final int targetMl;
  final String percentText;
  final double progressValue;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.water_drop_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_drink_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$percentText%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ScaleTransition(
                        scale: animation,
                        child: AnimatedCount(
                          value: glasses.toDouble(),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, val) {
                            return Text(
                              '${val.toInt()} gelas',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedCount(
                        value: dailyMl.toDouble(),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, val) {
                          return Text(
                            '${val.toInt()} / $targetMl ml',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progressValue),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              minHeight: 8,
                              value: value,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.25,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+250 ml per tap',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
