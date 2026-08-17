import 'package:flutter/material.dart';

import '../../../shared/widgets/nutrition_tile.dart';
import '../domain/product_view_data.dart';

class ProductNutritionGrid extends StatelessWidget {
  const ProductNutritionGrid({
    super.key,
    required this.item,
    this.packageAmountGrams,
    this.packageAmountLabel,
    required this.isPink,
  });

  final ProductViewData item;
  final double? packageAmountGrams;
  final String? packageAmountLabel;
  final bool isPink;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.75,
      children: [
        NutritionTile(
          label: 'Kalori',
          value: item.calories,
          unit: 'kcal/100g',
          color: isPink
              ? const Color(0xFFD81B60)
              : const Color(0xFFF39C12), // AppColors.warning approx
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Protein',
          value: item.protein,
          unit: 'g/100g',
          color: isPink
              ? const Color(0xFFEC407A)
              : const Color(0xFF9B59B6), // AppColors.accentStrong approx
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Lemak',
          value: item.fat,
          unit: 'g/100g',
          color: isPink ? const Color(0xFFF48FB1) : const Color(0xFF5BA7FF),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Karbohidrat',
          value: item.carbohydrates,
          unit: 'g/100g',
          color: const Color(0xFFF5C96A),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Gula',
          value: item.sugars,
          unit: 'g/100g',
          color: const Color(0xFFF1A7B3),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Lemak Jenuh',
          value: item.saturatedFat,
          unit: 'g/100g',
          color: const Color(0xFFC2B3F3),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Serat',
          value: item.fiber,
          unit: 'g/100g',
          color: const Color(0xFF8ED7A7),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Garam',
          value: item.salt,
          unit: 'g/100g',
          color: const Color(0xFF8FC9D1),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
        NutritionTile(
          label: 'Sodium',
          value: item.sodium,
          unit: 'g/100g',
          color: const Color(0xFFA7BBCB),
          packageAmountGrams: packageAmountGrams,
          packageAmountLabel: packageAmountLabel,
        ),
      ],
    );
  }
}
