import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../domain/nutrition_target.dart';
import 'dashboard_sections.dart';
import 'macro_summary_card.dart';
import 'profile_target_form.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/staggered_animated_tile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _boxName = 'profile_target_box';
  final _ageController = TextEditingController(text: '26');
  final _weightController = TextEditingController(text: '65');
  final _heightController = TextEditingController(text: '170');
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  DailyTarget? _target;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateTarget() {
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (age == null || weight == null || height == null) {
      TopLiquidSnackBar.show(
        context,
        message: 'Isi data umur, berat, dan tinggi dengan benar.',
        type: AppNotificationType.warning,
      );
      return;
    }

    final target = NutritionCalculator.calculate(
      age: age,
      weightKg: weight,
      heightCm: height,
      gender: _gender,
      activity: _activity,
    );

    setState(() => _target = target);
    _saveProfile(
      age: age,
      weight: weight,
      height: height,
      gender: _gender,
      activity: _activity,
      target: target,
    );
  }

  Future<void> _loadSavedProfile() async {
    final box = await _openProfileBox();
    final age = box.get('age') as int?;
    final weight = (box.get('weight') as num?)?.toDouble();
    final height = (box.get('height') as num?)?.toDouble();
    final gender = _parseGender(box.get('gender') as String?);
    final activity = _parseActivity(box.get('activity') as String?);
    final savedTarget = _readSavedTarget(box);

    if (!mounted) return;
    setState(() {
      if (age != null) _ageController.text = age.toString();
      if (weight != null) {
        _weightController.text = _formatWholeOrDecimal(weight);
      }
      if (height != null) {
        _heightController.text = _formatWholeOrDecimal(height);
      }
      if (gender != null) _gender = gender;
      if (activity != null) _activity = activity;
      _target = savedTarget;
    });
  }

  Future<void> _saveProfile({
    required int age,
    required double weight,
    required double height,
    required Gender gender,
    required ActivityLevel activity,
    required DailyTarget target,
  }) async {
    final box = await _openProfileBox();
    await box.putAll({
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender.name,
      'activity': activity.name,
      'target_calories': target.calories,
      'target_carbs_min': target.carbsMin,
      'target_carbs_max': target.carbsMax,
      'target_protein_min': target.proteinMin,
      'target_protein_max': target.proteinMax,
      'target_fat_min': target.fatMin,
      'target_fat_max': target.fatMax,
    });
  }

  Future<Box<dynamic>> _openProfileBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  DailyTarget? _readSavedTarget(Box<dynamic> box) {
    final calories = (box.get('target_calories') as num?)?.toDouble();
    final carbsMin = (box.get('target_carbs_min') as num?)?.toDouble();
    final carbsMax = (box.get('target_carbs_max') as num?)?.toDouble();
    final proteinMin = (box.get('target_protein_min') as num?)?.toDouble();
    final proteinMax = (box.get('target_protein_max') as num?)?.toDouble();
    final fatMin = (box.get('target_fat_min') as num?)?.toDouble();
    final fatMax = (box.get('target_fat_max') as num?)?.toDouble();

    if (calories == null ||
        carbsMin == null ||
        carbsMax == null ||
        proteinMin == null ||
        proteinMax == null ||
        fatMin == null ||
        fatMax == null) {
      return null;
    }

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

  Gender? _parseGender(String? value) {
    for (final item in Gender.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  ActivityLevel? _parseActivity(String? value) {
    for (final item in ActivityLevel.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  String _formatWholeOrDecimal(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final tileColor = isPink
        ? const Color(0xFFF48FB1)
        : const Color(0xFF90CAF9); // Soft theme colors

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                ),
              ),
            ),
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Profil Pengguna',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaggeredAnimatedTile(
                    index: 0,
                    child: ProfileTargetForm(
                      ageController: _ageController,
                      weightController: _weightController,
                      heightController: _heightController,
                      gender: _gender,
                      activity: _activity,
                      onGenderChanged: (v) => setState(() => _gender = v),
                      onActivityChanged: (v) => setState(() => _activity = v),
                      onCalculate: _calculateTarget,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_target != null)
                    StaggeredAnimatedTile(
                      index: 1,
                      child: MacroSummaryCard(target: _target!),
                    ),
                  const SizedBox(height: 24),
                  StaggeredAnimatedTile(
                    index: 2,
                    child: Text(
                      'Acuan Nutrisi per Kelompok',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const StaggeredAnimatedTile(
                    index: 3,
                    child: AgeReferenceGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
