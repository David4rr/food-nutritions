import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/pop_card.dart';
import '../domain/product_view_data.dart';
import 'product_analysis_row.dart';

class ProductAnalysisSections extends StatelessWidget {
  const ProductAnalysisSections({super.key, required this.item});

  final ProductViewData item;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final nutrientItems = _nutrientItems(item.nutrientLevelsTags, isPink);
    final ingredientItems = _ingredientItems(
      item.ingredientsAnalysisTags,
      isPink,
    );
    if (nutrientItems.isEmpty && ingredientItems.isEmpty) {
      return const SizedBox();
    }

    return PopCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Analisis Kandungan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: isPink ? const Color(0xFFAD1457) : Colors.blueGrey,
                  ),
                  tooltip: 'Info Analisis',
                  onPressed: () => _showInfo(context, isPink),
                ),
              ],
            ),
          ),
          if (nutrientItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Tingkat kandungan gizi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            ...nutrientItems,
          ],
          if (ingredientItems.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Analisis bahan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            ...ingredientItems,
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, bool isPink) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Info Analisis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warna pada analisis menunjukkan dampak:',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            _infoRow(
              isPink ? const Color(0xFFAD1457) : Colors.red,
              isPink
                  ? 'Pink gelap: Kandungan tinggi/negatif, konsumsi dengan bijak.'
                  : 'Merah: Kandungan tinggi/negatif, konsumsi dengan bijak.',
            ),
            _infoRow(
              isPink ? const Color(0xFFD81B60) : Colors.orange.shade600,
              isPink
                  ? 'Pink sedang: Kandungan sedang.'
                  : 'Kuning: Kandungan sedang.',
            ),
            _infoRow(
              isPink ? const Color(0xFFF48FB1) : Colors.green,
              isPink
                  ? 'Pink terang: Kandungan rendah/positif.'
                  : 'Hijau: Kandungan rendah/positif.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _nutrientItems(List<String>? tags, bool isPink) {
    int i = 0;
    return (tags ?? []).where((t) => t.contains('-in-')).map((raw) {
      final t = raw.replaceFirst('en:', '');
      final parts = t.split('-in-');
      final nutrient = _nutrientLabel(parts[0]);
      final levelKey = parts[1].replaceAll('-quantity', '').toLowerCase();
      final level = _levelLabel(levelKey);
      final color = switch (levelKey) {
        'high' => isPink ? const Color(0xFFAD1457) : const Color(0xFFE53935),
        'moderate' =>
          isPink ? const Color(0xFFD81B60) : const Color(0xFFF4B400),
        _ => isPink ? const Color(0xFFF48FB1) : const Color(0xFF1E8E3E),
      };
      return ProductAnalysisRow(
        text: '$nutrient: $level',
        color: color,
        index: i++,
      );
    }).toList();
  }

  List<Widget> _ingredientItems(List<String>? tags, bool isPink) {
    int i = 0;
    return (tags ?? []).where((t) => !t.endsWith('-unknown')).map((raw) {
      final t = raw.replaceFirst('en:', '');
      final isNegative = t.startsWith('non-') || t.contains('palm-oil');
      final color = isNegative
          ? (isPink ? const Color(0xFFAD1457) : const Color(0xFFE53935))
          : (isPink ? const Color(0xFFF48FB1) : const Color(0xFF1E8E3E));
      return ProductAnalysisRow(
        text: _ingredientLabel(t),
        color: color,
        index: i++,
      );
    }).toList();
  }

  String _nutrientLabel(String key) {
    return switch (key.toLowerCase()) {
      'fat' => 'Lemak',
      'saturated-fat' => 'Lemak jenuh',
      'sugars' => 'Gula',
      'salt' => 'Garam',
      _ => _title(key.replaceAll('-', ' ')),
    };
  }

  String _levelLabel(String level) {
    return switch (level) {
      'high' => 'Tinggi',
      'moderate' => 'Sedang',
      'low' => 'Rendah',
      _ => _title(level),
    };
  }

  String _ingredientLabel(String tag) {
    return switch (tag.toLowerCase()) {
      'vegan' => 'Cocok untuk vegan',
      'non-vegan' => 'Tidak cocok untuk vegan',
      'vegetarian' => 'Cocok untuk vegetarian',
      'non-vegetarian' => 'Tidak cocok untuk vegetarian',
      'palm-oil' => 'Mengandung minyak sawit',
      'palm-oil-free' => 'Bebas minyak sawit',
      _ => _title(tag.replaceAll('-', ' ')),
    };
  }

  String _title(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }
}
