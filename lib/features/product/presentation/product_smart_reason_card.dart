import 'package:flutter/material.dart';

import '../../../shared/widgets/pop_card.dart';
import '../domain/product_view_data.dart';
import 'product_quantity_helper.dart';

class ProductSmartReasonCard extends StatelessWidget {
  const ProductSmartReasonCard({super.key, required this.item});

  final ProductViewData item;

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights(item);
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekomendasi',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...insights.map((text) => _InsightLine(text: text)),
        ],
      ),
    );
  }

  List<String> _buildInsights(ProductViewData item) {
    final calories = item.calories;
    final protein = item.protein;
    final fat = item.fat;
    final servingLabel = item.servingSize?.trim();
    final quantityLabel = item.quantity?.trim();
    final packageLabel = (servingLabel != null && servingLabel.isNotEmpty)
        ? servingLabel
        : quantityLabel;
    final grams = parseEstimatedGrams(packageLabel);
    final productCalories = grams != null ? calories * (grams / 100) : null;
    final productProtein = grams != null ? protein * (grams / 100) : null;
    final productFat = grams != null ? fat * (grams / 100) : null;
    final carbs = item.carbohydrates ?? 0;
    final sugar = item.sugars ?? 0;
    final salt = item.salt ?? 0;

    if (calories == 0 && protein == 0 && fat == 0) {
      return const [
        'Data nutrisi detail belum tersedia sekarang.',
        'Scan ulang saat koneksi stabil untuk hasil lebih akurat.',
      ];
    }

    final sodiumRisk = salt >= 1.5
        ? 'tinggi'
        : (salt >= 0.6 ? 'sedang' : 'rendah');
    final sugarRisk = sugar >= 10
        ? 'tinggi'
        : (sugar >= 5 ? 'sedang' : 'rendah');

    final buyCadence = (salt >= 1.5 || sugar >= 10)
        ? '1x tiap 2-3 hari'
        : (salt >= 0.6 || sugar >= 5)
        ? '1x per hari (porsi terkontrol)'
        : 'aman untuk menu harian';

    final profiles = <String>[];
    if (protein >= 12 && calories >= 170) profiles.add('peningkatan massa');
    if (calories <= 130 && sugar <= 6 && fat <= 7) profiles.add('diet');
    if (carbs <= 12 && sugar <= 5) profiles.add('puasa intermiten');
    if (profiles.isEmpty) profiles.add('jaga berat badan');

    return [
      if (productCalories != null)
        'Perkiraan 1 kemasan ($packageLabel): ${productCalories.toStringAsFixed(0)} kkal, protein ${productProtein!.toStringAsFixed(1)}g, lemak ${productFat!.toStringAsFixed(1)}g.',
      'Gula ${sugar.toStringAsFixed(1)}g ($sugarRisk), garam ${salt.toStringAsFixed(1)}g ($sodiumRisk). Frekuensi beli: $buyCadence.',
      'Paling cocok untuk: ${profiles.join(', ')}.',
    ];
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '• $text',
              style: const TextStyle(fontSize: 14.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
