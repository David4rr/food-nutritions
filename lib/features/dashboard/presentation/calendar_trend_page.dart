import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../history/presentation/history_provider.dart';
import '../../../shared/widgets/animated_pressable.dart';

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
    // Simple year/month picker using showDatePicker (we just take the month/year)
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

    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final baseColor = isPink
        ? const Color(0xFFE45BA5)
        : const Color(0xFF2FB8A4);

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Aktivitas Bulanan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Navigation & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevMonth,
                    icon: const Icon(Icons.chevron_left_rounded, size: 32),
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
                            DateFormat('MMMM yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 16,
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
                    icon: const Icon(Icons.chevron_right_rounded, size: 32),
                  ),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kurang',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  for (var i = 1; i <= 5; i++) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? Colors.grey.shade200
                            : baseColor.withValues(alpha: i / 5.0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const Text(
                    'Target',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Calendar Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: GridView.builder(
                    key: ValueKey(
                      '${_selectedDate.year}-${_selectedDate.month}',
                    ),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio:
                          0.75, // Membuat kotak lebih tinggi untuk teks kalori
                    ),
                    itemCount:
                        monthData.emptyStartBlocks + monthData.daysInMonth,
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

                      final data = analytics[key];
                      final calories = data?.calories ?? 0.0;

                      return _CalendarBox(
                        date: date,
                        calories: calories,
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
    required this.target,
    required this.baseColor,
    required this.delayIndex,
  });

  final DateTime date;
  final double calories;
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
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(Duration(milliseconds: (widget.delayIndex % 31) * 15), () {
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

  void _showGlassmorphicSnackbar(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy').format(widget.date);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.calories.toStringAsFixed(0)} kkal',
                    style: TextStyle(
                      color: widget.baseColor
                          .withValues(alpha: 0.9)
                          .withAlpha(255),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color boxColor = Colors.grey.shade200;
    if (widget.calories > 0) {
      final ratio = (widget.calories / widget.target).clamp(0.2, 1.0);
      boxColor = widget.baseColor.withValues(alpha: ratio);
    }

    final hasRecord = widget.calories > 0;
    final isDarkBackground =
        hasRecord && (widget.calories / widget.target) > 0.5;
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
        onTap: () => _showGlassmorphicSnackbar(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isHovered ? 0.80 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasRecord ? textColor : Colors.grey.shade400,
                ),
              ),
              if (hasRecord) ...[
                const SizedBox(height: 2),
                Text(
                  _formatCalories(widget.calories),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
