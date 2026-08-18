import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../history/data/meal_entry.dart';
import '../../history/presentation/daily_meal_tracker_page.dart';
import '../../history/presentation/history_provider.dart';

class MonthData {
  const MonthData({
    required this.year,
    required this.month,
    required this.daysInMonth,
    required this.emptyStartBlocks,
  });
  final int year;
  final int month;
  final int daysInMonth;
  final int emptyStartBlocks;
}

class CalendarTrendPage extends StatefulWidget {
  const CalendarTrendPage({super.key, required this.targetCalories});
  final double targetCalories;

  @override
  State<CalendarTrendPage> createState() => _CalendarTrendPageState();
}

class _CalendarTrendPageState extends State<CalendarTrendPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  Future<void> _pickMonthYear() async {
    final initial = _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih Bulan & Tahun',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final analytics = history.getAllAnalytics();
    final target = widget.targetCalories > 0 ? widget.targetCalories : 2000.0;

    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final baseColor = palette?.scan ?? Theme.of(context).primaryColor;

    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;
    final emptyStartBlocks =
        DateTime(_selectedDate.year, _selectedDate.month, 1).weekday - 1;
    final monthData = MonthData(
      year: _selectedDate.year,
      month: _selectedDate.month,
      daysInMonth: daysInMonth,
      emptyStartBlocks: emptyStartBlocks,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
            ),
          ),
        ),
        title: Text(
          'Aktivitas Bulanan',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Navigation & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  ),
                  AnimatedPressable(
                    onPressed: _pickMonthYear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: baseColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  ),
                ],
              ),
            ),

            // Legend Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sedikit',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  for (var i = 1; i <= 5; i++) ...[
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? Colors.grey.shade200
                            : baseColor.withValues(alpha: i / 5.0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    'Target',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map(
                  (day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Calendar Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: GridView.builder(
                    key: ValueKey('${_selectedDate.year}-${_selectedDate.month}'),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.76,
                    ),
                    itemCount: monthData.emptyStartBlocks + monthData.daysInMonth,
                    itemBuilder: (context, index) {
                      if (index < monthData.emptyStartBlocks) {
                        return const SizedBox.shrink();
                      }
                      final day = index - monthData.emptyStartBlocks + 1;
                      final date = DateTime(
                        monthData.year,
                        monthData.month,
                        day,
                      );
                      final key =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                      // Real-time synchronization from both meal entries and analytics
                      final dayMeals = history.getMealsForDate(date);
                      final mealCals = dayMeals.fold<double>(0, (sum, m) => sum + m.calories);
                      final data = analytics[key];
                      final calories = mealCals > 0 ? mealCals : (data?.calories ?? 0.0);

                      return _CalendarBox(
                        date: date,
                        calories: calories,
                        meals: dayMeals,
                        target: target,
                        baseColor: baseColor,
                        delayIndex: day,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarBox extends StatefulWidget {
  const _CalendarBox({
    required this.date,
    required this.calories,
    required this.meals,
    required this.target,
    required this.baseColor,
    required this.delayIndex,
  });

  final DateTime date;
  final double calories;
  final List<MealEntry> meals;
  final double target;
  final Color baseColor;
  final int delayIndex;

  @override
  State<_CalendarBox> createState() => _CalendarBoxState();
}

class _CalendarBoxState extends State<_CalendarBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(Duration(milliseconds: (widget.delayIndex % 31) * 12), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCalories(double cals) {
    if (cals >= 1000) {
      return '${(cals / 1000).toStringAsFixed(1)}k';
    }
    return cals.toStringAsFixed(0);
  }

  void _showDayDetailSheet(BuildContext context) {
    final formatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.date);
    final totalProtein = widget.meals.fold<double>(0, (sum, m) => sum + m.protein);
    final totalCarbs = widget.meals.fold<double>(0, (sum, m) => sum + m.carbs);
    final totalFat = widget.meals.fold<double>(0, (sum, m) => sum + m.fat);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: widget.baseColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pill Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Date & Total Calories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatted,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.meals.length} item makanan dicatat',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.baseColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.calories.toStringAsFixed(0)} kkal',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: widget.baseColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (widget.calories > 0) ...[
                    const SizedBox(height: 14),
                    // Macro Summary Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MacroStat(label: 'Protein', value: '${totalProtein.toStringAsFixed(1)}g', color: widget.baseColor),
                          Container(width: 1, height: 22, color: Colors.black.withValues(alpha: 0.06)),
                          _MacroStat(label: 'Karbo', value: '${totalCarbs.toStringAsFixed(1)}g', color: widget.baseColor),
                          Container(width: 1, height: 22, color: Colors.black.withValues(alpha: 0.06)),
                          _MacroStat(label: 'Lemak', value: '${totalFat.toStringAsFixed(1)}g', color: widget.baseColor),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Open Full Diary Action Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.baseColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DailyMealTrackerPage(initialDate: widget.date),
                        ),
                      );
                    },
                    child: Text(
                      widget.calories > 0 ? 'Buka Jurnal Tanggal Ini' : '+ Catat Makanan di Tanggal Ini',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color boxColor = Colors.grey.shade200;
    if (widget.calories > 0) {
      final ratio = (widget.calories / widget.target).clamp(0.25, 1.0);
      boxColor = widget.baseColor.withValues(alpha: ratio);
    }

    final hasRecord = widget.calories > 0;
    final isDarkBackground =
        hasRecord && (widget.calories / widget.target) > 0.45;
    final textColor = isDarkBackground ? Colors.white : Colors.black87;
    final subTextColor = isDarkBackground ? Colors.white70 : Colors.black54;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isHovered = true);
        },
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () => _showDayDetailSheet(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: hasRecord
                  ? widget.baseColor.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: _isHovered && hasRecord
                ? [
                    BoxShadow(
                      color: widget.baseColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.date.day}',
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: hasRecord ? textColor : Colors.grey.shade400,
                ),
              ),
              if (hasRecord) ...[
                const SizedBox(height: 1),
                Text(
                  _formatCalories(widget.calories),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: subTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
