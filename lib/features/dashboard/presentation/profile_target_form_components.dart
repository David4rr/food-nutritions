import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_pressable.dart';

class ProfileTargetHeader extends StatelessWidget {
  const ProfileTargetHeader({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil Kamu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              Text(
                'Personalisasi target harian',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileTargetSaveButton extends StatelessWidget {
  const ProfileTargetSaveButton({
    super.key,
    required this.primary,
    required this.onCalculate,
  });

  final Color primary;
  final VoidCallback onCalculate;
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onPressed: onCalculate,
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              'Simpan Target',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
