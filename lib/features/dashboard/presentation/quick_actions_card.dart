import 'package:flutter/material.dart';

import 'dashboard_metro_tile.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    required this.onScan,
    required this.onClear,
    required this.canClear,
    required this.todayScans,
    required this.todayCalories,
  });

  final VoidCallback onScan;
  final VoidCallback onClear;
  final bool canClear;
  final int todayScans;
  final double todayCalories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12.0;
        final double width = constraints.maxWidth;

        // Responsive columns: 2 for mobile, 4 for tablet/web
        final int crossAxisCount = width > 600 ? 4 : 2;

        // Calculate base tile width (1 unit)
        final double baseWidth =
            (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final double baseHeight = 110.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            DashboardMetroTile(
              width: crossAxisCount == 4
                  ? (baseWidth * 2 + spacing)
                  : baseWidth,
              height: crossAxisCount == 4
                  ? baseHeight
                  : (baseHeight * 2 + spacing),
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Sekarang',
              subtitle: 'Baca barcode produk untuk melihat nutrisi detail',
              color: const Color(0xFF2FB8A4),
              onTap: onScan,
              large: true,
            ),
            if (crossAxisCount == 2) ...[
              SizedBox(
                width: baseWidth,
                height: (baseHeight * 2 + spacing),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DashboardMetroTile(
                      width: baseWidth,
                      height: baseHeight,
                      icon: Icons.delete_outline_rounded,
                      title: 'Clear',
                      subtitle: canClear ? 'Hapus riwayat' : 'Riwayat kosong',
                      color: const Color(0xFFF59E6D),
                      onTap: canClear ? onClear : null,
                    ),
                    DashboardMetroTile(
                      width: baseWidth,
                      height: baseHeight,
                      icon: Icons.inventory_2_outlined,
                      title: '$todayScans scan',
                      subtitle: 'Hari ini',
                      color: const Color(0xFF5BA7FF),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DashboardMetroTile(
                width: baseWidth,
                height: baseHeight,
                icon: Icons.delete_outline_rounded,
                title: 'Clear',
                subtitle: canClear ? 'Hapus' : 'Kosong',
                color: const Color(0xFFF59E6D),
                onTap: canClear ? onClear : null,
              ),
              DashboardMetroTile(
                width: baseWidth,
                height: baseHeight,
                icon: Icons.inventory_2_outlined,
                title: '$todayScans scan',
                subtitle: 'Hari ini',
                color: const Color(0xFF5BA7FF),
              ),
            ],
            DashboardMetroTile(
              width: width,
              height: baseHeight,
              icon: Icons.local_fire_department_outlined,
              title: '${todayCalories.toStringAsFixed(0)} kkal',
              subtitle: 'Total kalori dari scan hari ini',
              color: const Color(0xFF9B8AFB),
              horizontal: true,
            ),
          ],
        );
      },
    );
  }
}
