import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cue/cue.dart';
import '../../../shared/widgets/animated_pressable.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/nutrition_target.dart';
import 'profile_target_form_components.dart';

class ProfileTargetForm extends StatelessWidget {
  const ProfileTargetForm({
    super.key,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.gender,
    required this.activity,
    required this.onGenderChanged,
    required this.onActivityChanged,
    required this.onCalculate,
    this.primaryColor,
  });

  final TextEditingController ageController, weightController, heightController;
  final Gender gender;
  final ActivityLevel activity;
  final ValueChanged<Gender> onGenderChanged;
  final ValueChanged<ActivityLevel> onActivityChanged;
  final VoidCallback onCalculate;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final primary =
        primaryColor ?? palette?.profileCard ?? const Color(0xFF3F51B5);
    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.person_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileTargetHeader(primary: primary),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (_, constraints) {
                    if (constraints.maxWidth < 300) {
                      return Column(
                        children: [
                          _input(ageController, 'Umur'),
                          const SizedBox(height: 10),
                          _input(weightController, 'Berat'),
                          const SizedBox(height: 10),
                          _input(heightController, 'Tinggi'),
                        ],
                      );
                    }
                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _input(ageController, 'Umur')),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _input(weightController, 'Berat'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _input(heightController, 'Tinggi'),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: _input(ageController, 'Umur')),
                        const SizedBox(width: 10),
                        Expanded(child: _input(weightController, 'Berat')),
                        const SizedBox(width: 10),
                        Expanded(child: _input(heightController, 'Tinggi')),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (_, constraints) {
                    if (constraints.maxWidth < 320) {
                      return Column(
                        children: [
                          _genderDrop(primary),
                          const SizedBox(height: 10),
                          _activityDrop(primary),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _genderDrop(primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _activityDrop(primary)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                ProfileTargetSaveButton(
                  primary: primary,
                  onCalculate: onCalculate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderDrop(Color primary) {
    return _SmoothDrop<Gender>('Jenis Kelamin', gender, const [
      DropdownMenuItem(value: Gender.male, child: Text('Pria')),
      DropdownMenuItem(value: Gender.female, child: Text('Wanita')),
    ], onGenderChanged);
  }

  Widget _activityDrop(Color primary) {
    return _SmoothDrop<ActivityLevel>(
      'Aktivitas',
      activity,
      ActivityLevel.values
          .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
          .toList(),
      onActivityChanged,
    );
  }

  Widget _input(TextEditingController ctrl, String lbl) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    decoration: InputDecoration(
      labelText: lbl,
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white),
      ),
    ),
  );
}

// ponytail: smooth floating dropdown (no shaders, 60fps)
class _SmoothDrop<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  const _SmoothDrop(this.label, this.value, this.items, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.firstWhere(
      (e) => e.value == value,
      orElse: () => items.first,
    );

    // Normal trigger on the page (Glassmorphism to match text inputs)
    final trigger = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  child: selectedItem.child,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: Colors.white70,
            size: 22,
          ),
        ],
      ),
    );

    return CueModalTransition(
      motion: const CueMotion.snappy(),
      reverseMotion: const CueMotion.snappy(),
      hideTriggerOnTransition: true,
      triggerBuilder: (context, open) =>
          GestureDetector(onTap: open, child: trigger),
      builder: (context, rect) {
        return Stack(
          children: [
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              child: Material(
                color: Colors.transparent,
                child: Actor(
                  // Animate the entire dropdown card expanding from the trigger's top position
                  acts: [
                    const Act.scale(from: 0.8, alignment: Alignment.topCenter),
                    const Act.fadeIn(),
                  ],
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The anchor part (looks exactly like the trigger)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        DefaultTextStyle(
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          child: selectedItem.child,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Actor(
                                    acts: [Act.rotate(from: 0, to: 3.1415)],
                                    child: Icon(
                                      Icons.expand_less_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // The dropdown items
                            ...items.map((item) {
                              final isSelected = item.value == value;
                              return InkWell(
                                onTap: () {
                                  onChanged(item.value as T);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DefaultTextStyle(
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                    alpha: 0.8,
                                                  ),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                          child: item.child,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
