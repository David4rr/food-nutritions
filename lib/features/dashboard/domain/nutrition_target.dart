enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2, 'Sangat ringan'),
  light(1.375, 'Ringan'),
  moderate(1.55, 'Sedang'),
  active(1.725, 'Aktif'),
  athlete(1.9, 'Atlet');

  const ActivityLevel(this.factor, this.label);

  final double factor;
  final String label;
}

class DailyTarget {
  const DailyTarget({
    required this.calories,
    required this.carbsMin,
    required this.carbsMax,
    required this.proteinMin,
    required this.proteinMax,
    required this.fatMin,
    required this.fatMax,
  });

  final double calories;
  final double carbsMin;
  final double carbsMax;
  final double proteinMin;
  final double proteinMax;
  final double fatMin;
  final double fatMax;
}

class NutritionCalculator {
  const NutritionCalculator._();

  static DailyTarget calculate({
    required int age,
    required double weightKg,
    required double heightCm,
    required Gender gender,
    required ActivityLevel activity,
  }) {
    final bmr = gender == Gender.male
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

    final calories = bmr * activity.factor;
    final carbsMin = (calories * 0.45) / 4;
    final carbsMax = (calories * 0.65) / 4;
    final proteinMin = (calories * 0.10) / 4;
    final proteinMax = (calories * 0.35) / 4;
    final fatMin = (calories * 0.20) / 9;
    final fatMax = (calories * 0.35) / 9;

    return DailyTarget(
      calories: calories,
      carbsMin: carbsMin,
      carbsMax: carbsMax,
      proteinMin: proteinMin,
      proteinMax: proteinMax,
      fatMin: fatMin,
      fatMax: fatMax,
    );
  }
}
