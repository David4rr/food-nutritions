import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
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
      backgroundColor: Colors.transparent,
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

    // Auto-detect unit & capacity if available in quantity string (e.g. "1000 ml", "500 g")
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
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF2FB8A4),
            ),
          ),
          child: child!,
        );
      },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2FB8A4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${widget.product.name} berhasil disimpan ke ${_location.label}!',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = isPink ? const Color(0xFFE91E63) : const Color(0xFF2FB8A4);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.kitchen_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simpan ke Kulkas / Pantry',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Lokasi Penyimpanan (Tabs)
          Text(
            'Lokasi Penyimpanan',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: PantryLocation.values.map((loc) {
              final isSelected = _location == loc;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _location = loc),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          loc == PantryLocation.fridge
                              ? Icons.ac_unit_rounded
                              : (loc == PantryLocation.shelf ? Icons.inventory_2_outlined : Icons.severe_cold_rounded),
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // 2. Kapasitas Total & Satuan
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kapasitas Kemasan',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _capacityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
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
                      'Satuan',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          isExpanded: true,
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: Colors.black87),
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

          // 3. Porsi Quick Pour (Default Serving) & Tanggal Kedaluwarsa
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Takaran 1x Tuang / Ambil',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _servingController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                      decoration: InputDecoration(
                        suffixText: _unit,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickExpiryDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
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
                                  fontSize: 13,
                                  fontWeight: _expiryDate != null ? FontWeight.w800 : FontWeight.w500,
                                  color: _expiryDate != null ? Colors.black87 : Colors.grey.shade500,
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
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveToPantry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_add_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Simpan ke ${_location.label}',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800),
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
