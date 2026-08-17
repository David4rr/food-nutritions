import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../history/data/meal_entry.dart';
import '../../history/presentation/history_provider.dart';
import '../domain/product_view_data.dart';
import 'product_quantity_helper.dart';

enum MealCategory {
  breakfast('Sarapan', Icons.wb_twilight_rounded, Color(0xFFF59E0B)),
  lunch('Makan Siang', Icons.wb_sunny_rounded, Color(0xFF10B981)),
  dinner('Makan Malam', Icons.nights_stay_rounded, Color(0xFF6366F1)),
  snack('Camilan', Icons.cookie_rounded, Color(0xFFEC4899));

  const MealCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static MealCategory autoFromCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return MealCategory.breakfast;
    if (hour >= 11 && hour < 15) return MealCategory.lunch;
    if (hour >= 15 && hour < 18) return MealCategory.snack;
    return MealCategory.dinner;
  }

  MealTimeCategory toMealTimeCategory() {
    switch (this) {
      case MealCategory.breakfast:
        return MealTimeCategory.breakfast;
      case MealCategory.lunch:
        return MealTimeCategory.lunch;
      case MealCategory.dinner:
        return MealTimeCategory.dinner;
      case MealCategory.snack:
        return MealTimeCategory.snack;
    }
  }
}

class PortionSelectorSheet extends StatefulWidget {
  const PortionSelectorSheet({super.key, required this.product});

  final ProductViewData product;

  static Future<void> show(BuildContext context, ProductViewData product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortionSelectorSheet(product: product),
    );
  }

  @override
  State<PortionSelectorSheet> createState() => _PortionSelectorSheetState();
}

class _PortionSelectorSheetState extends State<PortionSelectorSheet> {
  late MealCategory _selectedCategory;
  late double _servingGrams;
  late double? _packageGrams;
  late double _currentGrams;
  late bool _isLiquid;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _selectedCategory = MealCategory.autoFromCurrentTime();

    final servingParsed = parseEstimatedGrams(widget.product.servingSize);
    final packageParsed = parseEstimatedGrams(widget.product.quantity);

    _packageGrams = packageParsed;
    _servingGrams = servingParsed ?? 100.0;
    _currentGrams = _servingGrams;

    final label = (widget.product.servingSize ?? widget.product.quantity ?? '').toLowerCase();
    _isLiquid = label.contains('ml') || label.contains('l') || label.contains('liter');
    _unit = _isLiquid ? 'ml' : 'g';
  }

  void _setPortion(double grams) {
    setState(() {
      _currentGrams = grams.clamp(1.0, 5000.0);
    });
  }

  double get _multiplier => _currentGrams / 100.0;
  double get _calcCalories => widget.product.calories * _multiplier;
  double get _calcProtein => widget.product.protein * _multiplier;
  double get _calcFat => widget.product.fat * _multiplier;
  double get _calcCarbs => (widget.product.carbohydrates ?? 0) * _multiplier;
  double get _calcSugars => (widget.product.sugars ?? 0) * _multiplier;

  Future<void> _submitIntake() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();

    final entry = MealEntry(
      id: '${widget.product.barcode}_${now.millisecondsSinceEpoch}',
      barcode: widget.product.barcode,
      name: widget.product.name,
      imageUrl: widget.product.imageUrl,
      category: _selectedCategory.toMealTimeCategory(),
      portionAmount: _currentGrams,
      portionUnit: _unit,
      calories: _calcCalories,
      protein: _calcProtein,
      fat: _calcFat,
      carbs: _calcCarbs,
      sugars: _calcSugars,
      loggedAt: now,
    );

    await context.read<HistoryProvider>().logMeal(entry);

    if (!mounted) return;
    Navigator.of(context).pop();

    TopLiquidSnackBar.show(
      context,
      message:
          '${_currentGrams.toStringAsFixed(0)} $_unit ${widget.product.name} (${_calcCalories.toStringAsFixed(0)} kkal) dicatat ke ${_selectedCategory.label}!',
      type: AppNotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DashboardTilePalette>();
    final isPink = theme.extension<AppVisualMeta>()?.isPink ?? false;
    final primaryColor = palette?.scan ?? theme.primaryColor;
    final gradientEnd = isPink ? (palette?.total ?? const Color(0xFFE91E63)) : const Color(0xFF1E8D7D);

    final maxSlider = (_packageGrams != null && _packageGrams! > 200)
        ? _packageGrams!
        : (_servingGrams * 3).clamp(300.0, 1000.0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 36,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pill Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header: Product & Category Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.2),
                            primaryColor.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        _isLiquid ? Icons.local_drink_rounded : Icons.restaurant_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catat Porsi Konsumsi',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.05),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Meal Time Selector (Sarapan, Siang, Malam, Camilan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: MealCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AnimatedPressable(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.black.withValues(alpha: 0.05),
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 20,
                                  color: isSelected ? primaryColor : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  cat.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? primaryColor : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Portion Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _PresetPill(
                      title: '1 Porsi',
                      subtitle: '${_servingGrams.toStringAsFixed(0)} $_unit',
                      isSelected: (_currentGrams - _servingGrams).abs() < 1,
                      onPressed: () => _setPortion(_servingGrams),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    _PresetPill(
                      title: '½ Porsi',
                      subtitle: '${(_servingGrams * 0.5).toStringAsFixed(0)} $_unit',
                      isSelected: (_currentGrams - (_servingGrams * 0.5)).abs() < 1,
                      onPressed: () => _setPortion(_servingGrams * 0.5),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    if (_packageGrams != null && _packageGrams! > _servingGrams) ...[
                      _PresetPill(
                        title: '1 Kemasan',
                        subtitle: '${_packageGrams!.toStringAsFixed(0)} $_unit',
                        isSelected: (_currentGrams - _packageGrams!).abs() < 1,
                        onPressed: () => _setPortion(_packageGrams!),
                        activeColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    _PresetPill(
                      title: 'Standar',
                      subtitle: '100 $_unit',
                      isSelected: (_currentGrams - 100.0).abs() < 1,
                      onPressed: () => _setPortion(100.0),
                      activeColor: primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Interactive Portion Dial / Stepper Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jumlah yang Dikonsumsi',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _currentGrams.toStringAsFixed(0),
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 28,
                                      color: primaryColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _unit,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _CircleStepBtn(
                                icon: Icons.remove_rounded,
                                onPressed: () => _setPortion(_currentGrams - 10),
                                primaryColor: primaryColor,
                              ),
                              const SizedBox(width: 10),
                              _CircleStepBtn(
                                icon: Icons.add_rounded,
                                onPressed: () => _setPortion(_currentGrams + 10),
                                primaryColor: primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: primaryColor.withValues(alpha: 0.15),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withValues(alpha: 0.18),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 3,
                          ),
                        ),
                        child: Slider(
                          value: _currentGrams.clamp(1.0, maxSlider),
                          min: 1.0,
                          max: maxSlider,
                          onChanged: (val) {
                            _setPortion(val.roundToDouble());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Live Real-Time Nutrition Breakdown Bento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.09),
                        primaryColor.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  color: primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Energi Nutrisi',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _calcCalories.toStringAsFixed(0),
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                  color: primaryColor,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'kkal',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MacroBento(
                              label: 'Protein',
                              value: '${_calcProtein.toStringAsFixed(1)}g',
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroBento(
                              label: 'Karbo',
                              value: '${_calcCarbs.toStringAsFixed(1)}g',
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroBento(
                              label: 'Lemak',
                              value: '${_calcFat.toStringAsFixed(1)}g',
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MacroBento(
                              label: 'Gula',
                              value: '${_calcSugars.toStringAsFixed(1)}g',
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Premium Capsule Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedPressable(
                  onPressed: _submitIntake,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.38),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Catat ke ${_selectedCategory.label} (${_calcCalories.toStringAsFixed(0)} kkal)',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onPressed,
    required this.activeColor,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleStepBtn extends StatelessWidget {
  const _CircleStepBtn({
    required this.icon,
    required this.onPressed,
    required this.primaryColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(icon, size: 20, color: primaryColor),
      ),
    );
  }
}

class _MacroBento extends StatelessWidget {
  const _MacroBento({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
