import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/widgets/pop_card.dart';
import '../domain/product_view_data.dart';
import 'product_nova_score_chip.dart';
import 'product_nutri_score_chip.dart';

class ProductScoreSection extends StatelessWidget {
  const ProductScoreSection({super.key, required this.item});

  final ProductViewData item;

  @override
  Widget build(BuildContext context) {
    final noNutriNova = item.nutriscore == null && item.novaGroup == null;
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Skor Produk',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (noNutriNova) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nutri-Score / NOVA belum tersedia untuk produk ini.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Menggunakan Column agar tidak berantakan (rata dan rapi secara vertikal)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item.nutriscore != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnimatedScoreChip(
                    index: 0,
                    child: NutriScoreChip(score: item.nutriscore),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnimatedScoreChip(
                  index: 1,
                  child: _EcoScoreChip(item: item),
                ),
              ),
              if (item.novaGroup != null)
                _AnimatedScoreChip(
                  index: 2,
                  child: NovaScoreChip(group: item.novaGroup),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedScoreChip extends StatefulWidget {
  const _AnimatedScoreChip({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedScoreChip> createState() => _AnimatedScoreChipState();
}

class _AnimatedScoreChipState extends State<_AnimatedScoreChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _EcoScoreChip extends StatelessWidget {
  const _EcoScoreChip({required this.item});

  final ProductViewData item;

  @override
  Widget build(BuildContext context) {
    final note = _ecoNote(item.ecoscore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FB8A4), Color(0xFF209483)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2FB8A4).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.ecoscoreIconUrl != null) ...[
                SizedBox(
                  height: 32,
                  child: SvgPicture.network(
                    item.ecoscoreIconUrl!,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const Icon(Icons.eco, size: 28, color: Colors.white),
                  ),
                ),
              ] else ...[
                const Icon(Icons.eco, size: 28, color: Colors.white),
              ],
              const SizedBox(width: 10),
              Text(
                'Eco-Score: ${item.ecoscore?.toUpperCase() ?? '-'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _ecoNote(String? score) {
    final g = (score ?? '').toLowerCase();
    if (g == 'a' || g == 'b') return 'Dampak lingkungan rendah';
    if (g == 'c') return 'Dampak lingkungan sedang';
    if (g == 'd' || g == 'e') return 'Dampak lingkungan tinggi';
    return 'Jejak lingkungan produk';
  }
}
