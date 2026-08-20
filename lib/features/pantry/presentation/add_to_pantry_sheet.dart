import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../product/domain/product_view_data.dart';
import '../domain/pantry_item.dart';
import 'pantry_provider.dart';

class AddToPantrySheet extends StatefulWidget {
  const AddToPantrySheet({
    super.key,
    required this.product,
  });

  final ProductViewData product;

  static Future<bool?> show(BuildContext context, ProductViewData product) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddToPantrySheet(product: product),
    );
  }

  @override
  State<AddToPantrySheet> createState() => _AddToPantrySheetState();
}

class _AddToPantrySheetState extends State<AddToPantrySheet> {
  late TextEditingController _capacityController;
  late TextEditingController _servingController;
  late String _unit;
  PantryLocation _location = PantryLocation.fridge;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final quantityStr = p.quantity?.toLowerCase() ?? '';

    if (quantityStr.contains('ml') || quantityStr.contains('l')) {
      _unit = 'ml';
      if (quantityStr.contains('1 l') || quantityStr.contains('1000')) {
        _capacityController = TextEditingController(text: '1000');
        _servingController = TextEditingController(text: '250');
      } else {
        final numMatch = RegExp(r'(\d+)').firstMatch(quantityStr);
        final val = numMatch != null ? numMatch.group(1)! : '500';
        _capacityController = TextEditingController(text: val);
        _servingController = TextEditingController(text: '200');
      }
    } else {
      _unit = 'g';
      final numMatch = RegExp(r'(\d+)').firstMatch(quantityStr);
      final val = numMatch != null ? numMatch.group(1)! : '500';
      _capacityController = TextEditingController(text: val);
      _servingController = TextEditingController(text: '100');
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 14)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveToPantry() async {
    final cap = double.tryParse(_capacityController.text.replaceAll(',', '.')) ?? 500.0;
    final serving = double.tryParse(_servingController.text.replaceAll(',', '.')) ?? 100.0;

    setState(() => _isSaving = true);

    try {
      await context.read<PantryProvider>().addProductToPantry(
            product: widget.product,
            totalCapacity: cap,
            unit: _unit,
            location: _location,
            defaultServingSize: serving,
            expiryDate: _expiryDate,
          );

      if (mounted) {
        Navigator.pop(context, true);
        TopLiquidSnackBar.show(
          context,
          message: '${widget.product.name} berhasil disimpan ke ${_location.label}!',
          type: AppNotificationType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.kitchen_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simpan ke Kulkas / Pantry',
                      style: GoogleFonts.dmSans(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 18),

          // 1. Lokasi Penyimpanan (Pills)
          Text(
            'Lokasi Penyimpanan',
            style: GoogleFonts.dmSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: PantryLocation.values.map((loc) {
              final isSelected = _location == loc;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: AnimatedPressable(
                    onPressed: () => setState(() => _location = loc),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.14)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryColor : cardBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            loc == PantryLocation.fridge
                                ? Icons.ac_unit_rounded
                                : (loc == PantryLocation.shelf
                                    ? Icons.inventory_2_outlined
                                    : Icons.severe_cold_rounded),
                            color: isSelected ? primaryColor : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? primaryColor : AppColors.textPrimary,
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
          const SizedBox(height: 16),

          // 2. Kapasitas & Satuan
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kapasitas Kemasan',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Satuan',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          isExpanded: true,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'g', child: Text('g')),
                            DropdownMenuItem(value: 'lembar', child: Text('lembar')),
                            DropdownMenuItem(value: 'butir', child: Text('butir')),
                            DropdownMenuItem(value: 'porsi', child: Text('porsi')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _unit = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Porsi Sekali Tuang & Tanggal Expired
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takaran Sekali Ambil',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _servingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                      decoration: InputDecoration(
                        suffixText: _unit,
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kedaluwarsa (Opsional)',
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickExpiryDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _expiryDate != null ? DateFormat('d MMM yyyy').format(_expiryDate!) : 'Pilih tgl',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: _expiryDate != null ? FontWeight.w700 : FontWeight.w500,
                                  color: _expiryDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Save Button
          AnimatedPressable(
            onPressed: _isSaving ? null : _saveToPantry,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Simpan ke ${_location.label}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
