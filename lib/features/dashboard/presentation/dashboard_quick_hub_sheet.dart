import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_style_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/utils/navigator_extension.dart';
import '../../pantry/presentation/pantry_page.dart';

class DashboardQuickHubSheet extends StatelessWidget {
  const DashboardQuickHubSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const DashboardQuickHubSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appStyle = context.watch<AppStyleController>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu & Tampilan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Opsi Kulkas & Pantry
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: const Icon(Icons.kitchen_rounded),
                title: const Text(
                  'Kulkas & Pantry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Kelola stok makanan dan pengingat kedaluwarsa'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                  context.pushRoute(const PantryPage());
                },
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Tema Tampilan',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Style Choice 1: Default
            _StyleChoiceTile(
              title: 'Default (sekarang)',
              subtitle: 'Nuansa asli aplikasi saat ini',
              selected: appStyle.style == AppVisualStyle.defaultStyle,
              onTap: () async {
                await appStyle.setStyle(AppVisualStyle.defaultStyle);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),

            // Style Choice 2: Pink Bloom
            _StyleChoiceTile(
              title: 'Pink Bloom',
              subtitle: 'Mayoritas pink dengan variasi tone di tile',
              selected: appStyle.style == AppVisualStyle.pinkBloom,
              onTap: () async {
                await appStyle.setStyle(AppVisualStyle.pinkBloom);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleChoiceTile extends StatelessWidget {
  const _StyleChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
        leading: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
