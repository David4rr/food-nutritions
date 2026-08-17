import 'package:flutter/material.dart';

class NutritionTile extends StatelessWidget {
  const NutritionTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.packageAmountGrams,
    this.packageAmountLabel,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;
  final double? packageAmountGrams;
  final String? packageAmountLabel;

  @override
  Widget build(BuildContext context) {
    final packageTotal = _packageTotal();
    final packageLabel = packageAmountLabel?.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        // ponytail: let it gracefully scale down text rather than overflow strict aspect ratios
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: value != null ? value!.toStringAsFixed(1) : '-',
                  ),
                  TextSpan(
                    text: value != null ? ' $unit' : '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (packageTotal != null &&
                packageLabel != null &&
                packageLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '≈ ${packageTotal.toStringAsFixed(1)} ${_baseUnit()} per 1 produk ($packageLabel)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? _packageTotal() {
    if (value == null || packageAmountGrams == null) return null;
    if (!unit.contains('/100g')) return null;
    return value! * (packageAmountGrams! / 100);
  }

  String _baseUnit() => unit.replaceAll('/100g', '');
}
