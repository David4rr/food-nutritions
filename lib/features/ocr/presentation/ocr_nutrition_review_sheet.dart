import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../history/presentation/history_provider.dart';
import '../../product/data/product_cache.dart';
import '../../product/data/product_cache_repository.dart';
import '../../product/presentation/product_detail_page.dart';
import '../domain/ocr_nutrition_result.dart';

class OcrNutritionReviewSheet extends StatefulWidget {
  const OcrNutritionReviewSheet({
    super.key,
    required this.initialResult,
  });

  final OcrNutritionResult initialResult;

  static Future<void> show(BuildContext context, OcrNutritionResult result) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => OcrNutritionReviewSheet(initialResult: result),
    );
  }

  @override
  State<OcrNutritionReviewSheet> createState() => _OcrNutritionReviewSheetState();
}

class _OcrNutritionReviewSheetState extends State<OcrNutritionReviewSheet> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _servingController;
  late TextEditingController _servingsPerContainerController;
  late TextEditingController _ingredientsController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _satFatController;
  late TextEditingController _carbsController;
  late TextEditingController _sugarsController;
  late TextEditingController _sodiumController;

  late String _servingUnit;
  bool _showIngredientsField = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initialResult;
    _nameController = TextEditingController(text: r.productName);
    _brandController = TextEditingController(text: r.brand ?? '');
    _servingUnit = (r.servingUnit.toLowerCase() == 'ml') ? 'ml' : 'g';
    _servingController = TextEditingController(
      text: r.servingSize > 0 ? (r.servingSize % 1 == 0 ? r.servingSize.toStringAsFixed(0) : r.servingSize.toStringAsFixed(1)) : '100',
    );
    _servingsPerContainerController = TextEditingController(
      text: r.servingsPerContainer > 0 ? (r.servingsPerContainer % 1 == 0 ? r.servingsPerContainer.toStringAsFixed(0) : r.servingsPerContainer.toStringAsFixed(1)) : '1',
    );
    _ingredientsController = TextEditingController(text: r.ingredients ?? '');
    _showIngredientsField = r.ingredients != null && r.ingredients!.trim().isNotEmpty;

    _caloriesController = TextEditingController(text: r.calories > 0 ? r.calories.toStringAsFixed(0) : '0');
    _proteinController = TextEditingController(text: r.protein.toStringAsFixed(1));
    _fatController = TextEditingController(text: r.fat.toStringAsFixed(1));
    _satFatController = TextEditingController(text: r.saturatedFat.toStringAsFixed(1));
    _carbsController = TextEditingController(text: r.carbohydrates.toStringAsFixed(1));
    _sugarsController = TextEditingController(text: r.sugars.toStringAsFixed(1));
    _sodiumController = TextEditingController(text: r.sodium.toStringAsFixed(0));

    // Rebuild on input changes for dynamic calculation badge
    _servingController.addListener(_onFieldChanged);
    _servingsPerContainerController.addListener(_onFieldChanged);
    _caloriesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _servingController.removeListener(_onFieldChanged);
    _servingsPerContainerController.removeListener(_onFieldChanged);
    _caloriesController.removeListener(_onFieldChanged);

    _nameController.dispose();
    _brandController.dispose();
    _servingController.dispose();
    _servingsPerContainerController.dispose();
    _ingredientsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _satFatController.dispose();
    _carbsController.dispose();
    _sugarsController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Produk Tabel Gizi (OCR)';
    final brand = _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null;
    final serving = _parse(_servingController);
    final servingsCount = _parse(_servingsPerContainerController);
    final ingredients = _ingredientsController.text.trim().isNotEmpty ? _ingredientsController.text.trim() : null;
    final calories = _parse(_caloriesController);
    final protein = _parse(_proteinController);
    final fat = _parse(_fatController);
    final satFat = _parse(_satFatController);
    final carbs = _parse(_carbsController);
    final sugars = _parse(_sugarsController);
    final sodium = _parse(_sodiumController);

    final finalResult = OcrNutritionResult(
      productName: name,
      brand: brand,
      servingSize: serving > 0 ? serving : 100.0,
      servingUnit: _servingUnit,
      servingsPerContainer: servingsCount > 0 ? servingsCount : 1.0,
      calories: calories,
      protein: protein,
      fat: fat,
      saturatedFat: satFat,
      carbohydrates: carbs,
      sugars: sugars,
      sodium: sodium,
      ingredients: ingredients,
      imagePath: widget.initialResult.imagePath,
      rawText: widget.initialResult.rawText,
    );

    final productView = finalResult.toProductViewData(fallbackName: name);

    final cacheRepo = context.read<ProductCacheRepository>();
    final historyProvider = context.read<HistoryProvider>();

    // 1. Simpan ke Cache Repository agar persist saat dibuka kembali
    try {
      await cacheRepo.put(
        ProductCache(
          barcode: productView.barcode,
          jsonData: productView.toJson(),
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 365)),
        ),
      );
    } catch (_) {}

    // 2. Simpan ke HistoryProvider (Riwayat Pindai)
    try {
      await historyProvider.addScan(productView);
    } catch (_) {}

    if (!mounted) return;

    Navigator.pop(context);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => ProductDetailPage(product: productView),
        transitionsBuilder: (_, animation, _, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutExpo));

          return SlideTransition(position: slideAnimation, child: child);
        },
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, String imagePath) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.5,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pinch_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Cubit / Geser untuk zoom foto tabel gizi',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualMeta = theme.extension<AppVisualMeta>();
    final palette = theme.extension<DashboardTilePalette>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = palette?.scan ?? (isPink ? const Color(0xFFE91E63) : AppColors.accent);

    final cardBorder = isPink
        ? primaryColor.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);

    final servingVal = _parse(_servingController);
    final servingsVal = _parse(_servingsPerContainerController);
    final calVal = _parse(_caloriesController);
    final totalWeight = (servingVal > 0 ? servingVal : 100.0) * (servingsVal > 0 ? servingsVal : 1.0);
    final totalCalories = calVal * (servingsVal > 0 ? servingsVal : 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              if (widget.initialResult.imagePath != null)
                GestureDetector(
                  onTap: () => _showImagePreviewDialog(context, widget.initialResult.imagePath!),
                  child: Stack(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
                          image: DecorationImage(
                            image: FileImage(File(widget.initialResult.imagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.document_scanner_rounded, color: primaryColor, size: 24),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Baca Tabel Gizi (OCR)',
                      style: GoogleFonts.dmSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Periksa dan sesuaikan takaran saji serta nilai gizi sebelum disimpan.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // OCR Raw Text Expansion or Blur Notice
          if (widget.initialResult.rawText.trim().isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Teks kemasan belum terbaca jelas. Pastikan tabel nilai gizi berada di dalam kotak pemindai dan pencahayaan cukup.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.text_snippet_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Lihat Teks Hasil Scan Kamera',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorder),
                    ),
                    child: SelectableText(
                      widget.initialResult.rawText,
                      style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // Product & Brand Names
          TextField(
            controller: _nameController,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14.5),
            decoration: InputDecoration(
              labelText: 'Nama Produk / Makanan',
              hintText: 'Misal: Susu UHT Cokelat, Roti Gandum',
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _brandController,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Merek / Brand (Opsional)',
              hintText: 'Misal: Ultra Milk, Sari Roti',
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // Serving & Packaging Header
          Text(
            'Informasi Takaran Saji & Kemasan',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Serving Size, Unit Toggle, and Servings per container Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Takaran Saji
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _servingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Takaran Saji',
                    hintText: 'Misal: 30',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Satuan Unit Selector (g / ml)
              Container(
                height: 48,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UnitChip(
                      label: 'g',
                      isSelected: _servingUnit == 'g',
                      primaryColor: primaryColor,
                      onTap: () => setState(() => _servingUnit = 'g'),
                    ),
                    _UnitChip(
                      label: 'ml',
                      isSelected: _servingUnit == 'ml',
                      primaryColor: primaryColor,
                      onTap: () => setState(() => _servingUnit = 'ml'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Sajian per Kemasan
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _servingsPerContainerController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Porsi/Kemasan',
                    hintText: 'Misal: 4',
                    suffixText: 'porsi',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Total Package Weight & Calories Calculation Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Total 1 Kemasan: ~${totalWeight > 0 ? (totalWeight % 1 == 0 ? totalWeight.toStringAsFixed(0) : totalWeight.toStringAsFixed(1)) : '100'} $_servingUnit (${servingsVal > 0 ? (servingsVal % 1 == 0 ? servingsVal.toStringAsFixed(0) : servingsVal.toStringAsFixed(1)) : '1'} sajian) • ~${totalCalories.round()} kkal',
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Komposisi / Ingredients Section Toggle
          InkWell(
            onTap: () => setState(() => _showIngredientsField = !_showIngredientsField),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _showIngredientsField ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Komposisi / Bahan-bahan (Ingredients)',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (_ingredientsController.text.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Terdeteksi',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_showIngredientsField) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _ingredientsController,
              maxLines: 3,
              style: GoogleFonts.dmSans(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Misal: Tepung terigu, gula, minyak nabati, susu bubuk, pengemulsi lesitin...',
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Nutrients Grid Header
          Text(
            'Kandungan Nutrisi (Per Sajian / ${_servingController.text.trim().isNotEmpty ? _servingController.text.trim() : '100'} $_servingUnit)',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // 2x3 Grid of Nutrition Inputs
          Row(
            children: [
              Expanded(
                child: _NutrientInput(
                  label: 'Energi / Kalori',
                  controller: _caloriesController,
                  unit: 'kkal',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NutrientInput(
                  label: 'Protein',
                  controller: _proteinController,
                  unit: 'g',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NutrientInput(
                  label: 'Lemak Total',
                  controller: _fatController,
                  unit: 'g',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NutrientInput(
                  label: 'Lemak Jenuh',
                  controller: _satFatController,
                  unit: 'g',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NutrientInput(
                  label: 'Karbohidrat',
                  controller: _carbsController,
                  unit: 'g',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NutrientInput(
                  label: 'Gula',
                  controller: _sugarsController,
                  unit: 'g',
                  cardBorder: cardBorder,
                  primaryColor: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NutrientInput(
            label: 'Natrium (Sodium)',
            controller: _sodiumController,
            unit: 'mg',
            cardBorder: cardBorder,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 22),

          // Action Button
          AnimatedPressable(
            onPressed: _submit,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Simpan ke Riwayat & Buka Detail',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
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

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _NutrientInput extends StatelessWidget {
  const _NutrientInput({
    required this.label,
    required this.controller,
    required this.unit,
    required this.cardBorder,
    required this.primaryColor,
  });

  final String label;
  final TextEditingController controller;
  final String unit;
  final Color cardBorder;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }
}
