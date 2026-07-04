import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_pressable.dart';

class DashboardMetroTile extends StatelessWidget {
  const DashboardMetroTile({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.large = false,
    this.horizontal = false,
  });

  final double width;
  final double height;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool large;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onPressed: onTap,
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
              right: horizontal ? 24 : -16,
              top: horizontal ? null : -16,
              bottom: horizontal ? -24 : null,
              child: Icon(
                icon,
                size: horizontal ? 100 : (large ? 120 : 80),
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(large ? 20 : 16),
                child: horizontal
                    ? _horizontalContent(context)
                    : _verticalContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: large ? 36 : 28),
        const Spacer(),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: large ? 20 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: large ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _horizontalContent(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
