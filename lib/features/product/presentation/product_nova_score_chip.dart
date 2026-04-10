import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NovaScoreChip extends StatelessWidget {
  const NovaScoreChip({super.key, required this.group});

  final int? group;

  @override
  Widget build(BuildContext context) {
    final isValidGroup = group != null && group! >= 1 && group! <= 4;
    final url = isValidGroup
        ? 'https://static.openfoodfacts.org/images/attributes/dist/nova-group-${group!}.svg'
        : null;
    final note = _noteForGroup(group);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E6D), Color(0xFFE87F4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E6D).withValues(alpha: 0.3),
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
                    placeholderBuilder: (_) => _NovaFallbackBadge(group: group),
                  ),
                ),
              ] else ...[
                const SizedBox(
                  height: 32,
                  child: Center(child: _NovaFallbackBadge(group: null)),
                ),
              ],
              const SizedBox(width: 10),
              const Text(
                'NOVA',
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

  String _noteForGroup(int? group) {
    switch (group) {
      case 1:
        return 'Minim diproses';
      case 2:
        return 'Bahan olahan masak';
      case 3:
        return 'Makanan olahan';
      case 4:
        return 'Ultra processed';
      default:
        return 'Tingkat pemrosesan';
    }
  }
}

class _NovaFallbackBadge extends StatelessWidget {
  const _NovaFallbackBadge({required this.group});

  final int? group;

  @override
  Widget build(BuildContext context) {
    final text = group != null ? '$group' : 'N/A';
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
