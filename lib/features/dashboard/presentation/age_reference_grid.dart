import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

class AgeReferenceGrid extends StatelessWidget {
  const AgeReferenceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final cardColors = isPink
        ? const [
            Color(0xFFF48FB1),
            Color(0xFFEC407A),
            Color(0xFFD81B60),
            Color(0xFFAD1457),
          ]
        : const [
            Color(0xFFFFB900),
            Color(0xFF00A4D3),
            Color(0xFFF25022),
            Color(0xFF7FBA00),
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid layout for larger screens
        final int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95, // Slightly taller tiles
          children: [
            _ReferenceCard(
              title: 'Anak 6-12',
              calories: '1.600 - 2.200',
              protein: '35-50g',
              fiber: '20g',
              focus: 'Fokus Pertumbuhan',
              color: cardColors[0],
              icon: Icons.child_care_rounded,
            ),
            _ReferenceCard(
              title: 'Dewasa Pria',
              calories: '2.400 - 2.700',
              protein: '65-80g',
              fiber: '30-35g',
              focus: 'Stamina & Otot',
              color: cardColors[1],
              icon: Icons.man_rounded,
            ),
            _ReferenceCard(
              title: 'Dewasa Wanita',
              calories: '2.000 - 2.300',
              protein: '55-65g',
              fiber: '25g',
              focus: 'Energi Hormonal',
              color: cardColors[2],
              icon: Icons.woman_rounded,
            ),
            _ReferenceCard(
              title: 'Lansia 60+',
              calories: '1.800 - 2.100',
              protein: '70g+',
              fiber: '30g',
              focus: 'Pelindung Sendi',
              color: cardColors[3],
              icon: Icons.elderly_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({
    required this.title,
    required this.calories,
    required this.protein,
    required this.fiber,
    required this.focus,
    required this.color,
    required this.icon,
  });

  final String title;
  final String calories;
  final String protein;
  final String fiber;
  final String focus;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -10,
            child: Icon(
              icon,
              size: 110,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _DataRow(label: 'Kkal', value: calories),
                _DataRow(label: 'Pro', value: protein),
                _DataRow(label: 'Serat', value: fiber),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    focus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
