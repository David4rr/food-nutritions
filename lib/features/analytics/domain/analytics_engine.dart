import '../../history/presentation/history_provider.dart';

class DayEntry {
  const DayEntry(this.date, this.calories, this.protein, this.fat, this.carbs);
  final DateTime date;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
}

class AnalyticsData {
  const AnalyticsData({
    required this.dailyEntries,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgFat,
    required this.avgCarbs,
    required this.targetCalories,
    required this.targetProtein,
    required this.macroProtein,
    required this.macroFat,
    required this.macroCarbs,
    required this.totalScans,
    required this.bestDay,
    required this.worstDay,
    required this.calorieTrendPercent,
    required this.insights,
  });

  final List<DayEntry> dailyEntries;
  final double avgCalories;
  final double avgProtein;
  final double avgFat;
  final double avgCarbs;
  final double targetCalories;
  final double targetProtein;
  final double macroProtein;
  final double macroFat;
  final double macroCarbs;
  final int totalScans;
  final String bestDay;
  final String worstDay;
  final double calorieTrendPercent;
  final List<String> insights;
}

class AnalyticsEngine {
  static AnalyticsData compute({
    required HistoryProvider history,
    required double tCal,
    required double tPro,
  }) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    List<DayEntry> thisWeek = [];
    List<DayEntry> lastWeek = [];
    int totalWeeklyMeals = 0;

    for (var i = 6; i >= 0; i--) {
      final date = startOfToday.subtract(Duration(days: i));
      final dayMeals = history.getMealsForDate(date);
      totalWeeklyMeals += dayMeals.length;

      final c = dayMeals.fold<double>(0, (sum, m) => sum + m.calories);
      final p = dayMeals.fold<double>(0, (sum, m) => sum + m.protein);
      final f = dayMeals.fold<double>(0, (sum, m) => sum + m.fat);
      final carbs = dayMeals.fold<double>(0, (sum, m) => sum + m.carbs);

      thisWeek.add(DayEntry(date, c, p, f, carbs));

      final dateLast = startOfToday.subtract(Duration(days: i + 7));
      final lastMeals = history.getMealsForDate(dateLast);
      final cLast = lastMeals.fold<double>(0, (sum, m) => sum + m.calories);
      final pLast = lastMeals.fold<double>(0, (sum, m) => sum + m.protein);
      final fLast = lastMeals.fold<double>(0, (sum, m) => sum + m.fat);
      final carbsLast = lastMeals.fold<double>(0, (sum, m) => sum + m.carbs);

      lastWeek.add(DayEntry(dateLast, cLast, pLast, fLast, carbsLast));
    }

    final totalCalThisWeek = thisWeek.fold<double>(
      0,
      (sum, e) => sum + e.calories,
    );
    final totalCalLastWeek = lastWeek.fold<double>(
      0,
      (sum, e) => sum + e.calories,
    );

    final avgCal = totalCalThisWeek / 7;
    final avgPro = thisWeek.fold<double>(0, (sum, e) => sum + e.protein) / 7;
    final avgFat = thisWeek.fold<double>(0, (sum, e) => sum + e.fat) / 7;
    final avgCarbs = thisWeek.fold<double>(0, (sum, e) => sum + e.carbs) / 7;

    double trend = 0.0;
    if (totalCalLastWeek > 0) {
      trend = ((totalCalThisWeek - totalCalLastWeek) / totalCalLastWeek) * 100;
    }

    final totalMacros = avgPro + avgFat + avgCarbs;
    final macroP = totalMacros > 0 ? (avgPro / totalMacros) : 0.0;
    final macroF = totalMacros > 0 ? (avgFat / totalMacros) : 0.0;
    final macroC = totalMacros > 0 ? (avgCarbs / totalMacros) : 0.0;

    final sortedDays = List<DayEntry>.from(thisWeek)
      ..sort((a, b) {
        final diffA = (a.calories - tCal).abs();
        final diffB = (b.calories - tCal).abs();
        return diffA.compareTo(diffB);
      });

    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final bestDay = sortedDays.first.calories > 0
        ? weekdays[sortedDays.first.date.weekday - 1]
        : '-';
    final worstDay = sortedDays.last.calories > 0
        ? weekdays[sortedDays.last.date.weekday - 1]
        : '-';

    final insights = <String>[];
    if (avgPro < tPro) {
      insights.add(
        'Protein mingguan rata-rata di bawah target (${tPro.toStringAsFixed(0)}g). Tambah lauk tinggi protein.',
      );
    } else {
      insights.add(
        'Asupan protein sangat baik dan konsisten minggu ini! Pertahankan.',
      );
    }

    if (trend > 10) {
      insights.add(
        'Terjadi lonjakan kalori sebesar ${trend.toStringAsFixed(1)}% dibanding minggu lalu.',
      );
    } else if (trend < -10) {
      insights.add(
        'Defisit kalori cukup signifikan (${trend.toStringAsFixed(1)}%) dari minggu sebelumnya.',
      );
    } else {
      insights.add(
        'Asupan kalori kamu cukup stabil jika dibandingkan dengan minggu sebelumnya.',
      );
    }

    return AnalyticsData(
      dailyEntries: thisWeek,
      avgCalories: avgCal,
      avgProtein: avgPro,
      avgFat: avgFat,
      avgCarbs: avgCarbs,
      targetCalories: tCal,
      targetProtein: tPro,
      macroProtein: macroP,
      macroFat: macroF,
      macroCarbs: macroC,
      totalScans: totalWeeklyMeals,
      bestDay: bestDay,
      worstDay: worstDay,
      calorieTrendPercent: trend,
      insights: insights,
    );
  }
}
