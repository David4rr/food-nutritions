import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../app/theme/app_theme.dart';
import 'water_tracker_tile_view.dart';

class HydrationTrackerTile extends StatefulWidget {
  const HydrationTrackerTile({
    super.key,
    required this.width,
    required this.height,
    required this.profileBox,
    this.onCelebrate,
  });

  final double width;
  final double height;
  final Box<dynamic> profileBox;
  final VoidCallback? onCelebrate;

  @override
  State<HydrationTrackerTile> createState() => _HydrationTrackerTileState();
}

class _HydrationTrackerTileState extends State<HydrationTrackerTile>
    with SingleTickerProviderStateMixin {
  static const _waterBoxName = 'water_tracker_box';
  static const _stepMl = 250;

  late final AnimationController _pulseController;
  late final Animation<double> _animation;

  Box<dynamic>? _waterBox;
  int _dailyMl = 0;

  int get _glasses => (_dailyMl / _stepMl).floor();
  int get _targetMl {
    final weightKg = (widget.profileBox.get('weight') as num?)?.toDouble();
    if (weightKg == null || weightKg <= 0) return 2000;
    return (weightKg * 30).round();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _loadWaterState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterState() async {
    final box = Hive.isBoxOpen(_waterBoxName)
        ? Hive.box<dynamic>(_waterBoxName)
        : await Hive.openBox<dynamic>(_waterBoxName);

    final today = _todayKey();
    final savedDate = box.get('date_key') as String?;
    if (savedDate != today) {
      await box.put('date_key', today);
      await box.put('daily_ml', 0);
      await box.put('celebrated_date', '');
    }

    if (!mounted) return;
    setState(() {
      _waterBox = box;
      _dailyMl = (box.get('daily_ml') as int?) ?? 0;
    });
  }

  Future<void> _addWater() async {
    if (_waterBox == null) return;

    final oldMl = _dailyMl;
    final newMl = _dailyMl + _stepMl;

    setState(() => _dailyMl = newMl);
    await _waterBox!.put('daily_ml', newMl);
    _pulseController.forward().then((_) => _pulseController.reverse());

    final reachedByGlasses = _glasses >= 8;
    final reachedByTarget = _targetMl > 0 && newMl >= _targetMl;
    final wasReachedByGlasses = (oldMl / _stepMl).floor() >= 8;
    final wasReachedByTarget = _targetMl > 0 && oldMl >= _targetMl;

    if ((reachedByGlasses || reachedByTarget) &&
        !(wasReachedByGlasses || wasReachedByTarget)) {
      await _triggerCelebrationOncePerDay();
    }
  }

  Future<void> _triggerCelebrationOncePerDay() async {
    if (_waterBox == null) return;
    final today = _todayKey();
    final celebrated = _waterBox!.get('celebrated_date') as String?;
    if (celebrated == today) return;

    await _waterBox!.put('celebrated_date', today);
    if (!mounted) return;
    widget.onCelebrate?.call();
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Color _tileColor({required bool isPink}) {
    final ratio = _targetMl <= 0 ? 0.0 : _dailyMl / _targetMl;
    if (ratio <= 1) {
      return Color.lerp(
        isPink ? const Color(0xFFF48FB1) : const Color(0xFF58C7F3),
        isPink ? const Color(0xFFD81B60) : const Color(0xFF0096C7),
        ratio,
      )!;
    }
    final overRatio = ((ratio - 1) / 1.5).clamp(0.0, 1.0);
    return Color.lerp(
      isPink ? const Color(0xFFC2185B) : const Color(0xFF0096C7),
      isPink ? const Color(0xFF880E4F) : const Color(0xFFE53935),
      overRatio,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final ratio = _targetMl <= 0 ? 0.0 : _dailyMl / _targetMl;
    return WaterTrackerTileView(
      width: widget.width,
      height: widget.height,
      color: _tileColor(isPink: isPink),
      glasses: _glasses,
      dailyMl: _dailyMl,
      targetMl: _targetMl,
      percentText: (ratio * 100).toStringAsFixed(0),
      progressValue: ratio.clamp(0.0, 1.0),
      animation: _animation,
      onTap: _addWater,
    );
  }
}
