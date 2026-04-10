import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

import '../../../shared/widgets/pop_card.dart';

class ProductIngredientsCard extends StatelessWidget {
  const ProductIngredientsCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    return PopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt_rounded,
                color: isPink
                    ? const Color(0xFFD81B60)
                    : const Color(0xFF2FB8A4),
              ),
              const SizedBox(width: 8),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

class ProductSourceCard extends StatelessWidget {
  const ProductSourceCard({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    return PopCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.public_rounded,
              color: isPink ? const Color(0xFFEC407A) : const Color(0xFF5BA7FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sumber data: $url',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
