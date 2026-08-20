import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../scanner/presentation/scanner_page.dart';
import '../data/meal_entry.dart';
import 'history_provider.dart';

class DailyMealTrackerPage extends StatefulWidget {
  const DailyMealTrackerPage({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DailyMealTrackerPage> createState() => _DailyMealTrackerPageState();
}

class _DailyMealTrackerPageState extends State<DailyMealTrackerPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _openScanner() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ScannerPage(),
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DashboardTilePalette>();
    final isPink = theme.extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = palette?.scan ?? theme.primaryColor;
    final cardBorder = isPink
        ? primaryColor.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: AnimatedPressable(
        onPressed: _openScanner,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Scan Makanan',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          final dayMeals = provider.getMealsForDate(_selectedDate);

          final totalCalories = dayMeals.fold<double>(0, (sum, item) => sum + item.calories);
          final totalProtein = dayMeals.fold<double>(0, (sum, item) => sum + item.protein);
          final totalFat = dayMeals.fold<double>(0, (sum, item) => sum + item.fat);
          final totalCarbs = dayMeals.fold<double>(0, (sum, item) => sum + item.carbs);

          final breakfastItems = dayMeals.where((m) => m.category == MealTimeCategory.breakfast).toList();
          final lunchItems = dayMeals.where((m) => m.category == MealTimeCategory.lunch).toList();
          final dinnerItems = dayMeals.where((m) => m.category == MealTimeCategory.dinner).toList();
          final snackItems = dayMeals.where((m) => m.category == MealTimeCategory.snack).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeInOutCubic,
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                foregroundColor: Colors.black87,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: const Text(
                  'Jurnal Makan',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Minimalist Date Switcher Bar
                    _MinimalDateBar(
                      selectedDate: _selectedDate,
                      isToday: _isToday,
                      onPrevious: _previousDay,
                      onNext: _nextDay,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                    ),

                    const SizedBox(height: 12),

                    // Minimalist Monochromatic Summary Card
                    _MinimalSummaryCard(
                      calories: totalCalories,
                      protein: totalProtein,
                      carbs: totalCarbs,
                      fat: totalFat,
                      mealCount: dayMeals.length,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                      isPink: isPink,
                    ),

                    const SizedBox(height: 16),

                    // Category Section: Sarapan
                    _MinimalMealSection(
                      category: MealTimeCategory.breakfast,
                      icon: Icons.wb_twilight_rounded,
                      items: breakfastItems,
                      onDeleteItem: (item) => _confirmDeleteItem(context, provider, item),
                      onScanTap: _openScanner,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                    ),

                    const SizedBox(height: 12),

                    // Category Section: Makan Siang
                    _MinimalMealSection(
                      category: MealTimeCategory.lunch,
                      icon: Icons.wb_sunny_rounded,
                      items: lunchItems,
                      onDeleteItem: (item) => _confirmDeleteItem(context, provider, item),
                      onScanTap: _openScanner,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                    ),

                    const SizedBox(height: 12),

                    // Category Section: Makan Malam
                    _MinimalMealSection(
                      category: MealTimeCategory.dinner,
                      icon: Icons.nights_stay_rounded,
                      items: dinnerItems,
                      onDeleteItem: (item) => _confirmDeleteItem(context, provider, item),
                      onScanTap: _openScanner,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                    ),

                    const SizedBox(height: 12),

                    // Category Section: Camilan & Minuman
                    _MinimalMealSection(
                      category: MealTimeCategory.snack,
                      icon: Icons.cookie_rounded,
                      items: snackItems,
                      onDeleteItem: (item) => _confirmDeleteItem(context, provider, item),
                      onScanTap: _openScanner,
                      primaryColor: primaryColor,
                      borderColor: cardBorder,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteItem(BuildContext scaffoldContext, HistoryProvider provider, MealEntry item) {
    showDialog(
      context: scaffoldContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Catatan Makanan?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${item.name} (${item.portionAmount.toStringAsFixed(0)} ${item.portionUnit}) dari jurnal?',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              await provider.removeMeal(item);
              if (scaffoldContext.mounted) {
                TopLiquidSnackBar.show(
                  scaffoldContext,
                  message: '${item.name} berhasil dihapus dari jurnal.',
                  type: AppNotificationType.info,
                );
              }
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalDateBar extends StatelessWidget {
  const _MinimalDateBar({
    required this.selectedDate,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.primaryColor,
    required this.borderColor,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color primaryColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final dateStr = isToday
        ? 'Hari Ini, ${DateFormat('d MMM yyyy', 'id_ID').format(selectedDate)}'
        : DateFormat('EEEE, d MMM yyyy', 'id_ID').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            color: AppColors.textPrimary,
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 15, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: isToday ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            color: isToday ? Colors.grey.shade300 : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _MinimalSummaryCard extends StatelessWidget {
  const _MinimalSummaryCard({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealCount,
    required this.primaryColor,
    required this.borderColor,
    required this.isPink,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int mealCount;
  final Color primaryColor;
  final Color borderColor;
  final bool isPink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ASUPAN HARI INI',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        calories.toStringAsFixed(0),
                        style: GoogleFonts.dmSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'kkal',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$mealCount Makanan',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MinimalMacroCol(
                  label: 'Protein',
                  val: '${protein.toStringAsFixed(1)}g',
                  primaryColor: primaryColor,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.06)),
              Expanded(
                child: _MinimalMacroCol(
                  label: 'Karbohidrat',
                  val: '${carbs.toStringAsFixed(1)}g',
                  primaryColor: primaryColor,
                ),
              ),
              Container(width: 1, height: 28, color: Colors.black.withValues(alpha: 0.06)),
              Expanded(
                child: _MinimalMacroCol(
                  label: 'Lemak',
                  val: '${fat.toStringAsFixed(1)}g',
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimalMacroCol extends StatelessWidget {
  const _MinimalMacroCol({
    required this.label,
    required this.val,
    required this.primaryColor,
  });

  final String label;
  final String val;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MinimalMealSection extends StatelessWidget {
  const _MinimalMealSection({
    required this.category,
    required this.icon,
    required this.items,
    required this.onDeleteItem,
    required this.onScanTap,
    required this.primaryColor,
    required this.borderColor,
  });

  final MealTimeCategory category;
  final IconData icon;
  final List<MealEntry> items;
  final ValueChanged<MealEntry> onDeleteItem;
  final VoidCallback onScanTap;
  final Color primaryColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final sectionCalories = items.fold<double>(0, (sum, i) => sum + i.calories);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clean Monochromatic Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          category.timeRange,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${sectionCalories.toStringAsFixed(0)} kkal',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: items.isNotEmpty ? primaryColor : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items List or Minimal Add Trigger
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedPressable(
                onPressed: onScanTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: primaryColor, size: 17),
                      const SizedBox(width: 6),
                      Text(
                        'Catat ${category.label}',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = items[idx];
                return _MinimalMealItemTile(
                  item: item,
                  onDelete: () => onDeleteItem(item),
                  primaryColor: primaryColor,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MinimalMealItemTile extends StatelessWidget {
  const _MinimalMealItemTile({
    required this.item,
    required this.onDelete,
    required this.primaryColor,
  });

  final MealEntry item;
  final VoidCallback onDelete;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: primaryColor.withValues(alpha: 0.08),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.restaurant_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                    )
                  : Icon(
                      Icons.restaurant_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${item.portionAmount.toStringAsFixed(0)} ${item.portionUnit}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.calories.toStringAsFixed(0)} kkal',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    if (item.protein > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.protein.toStringAsFixed(1)}g Prot',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: Colors.grey.shade400,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }
}
