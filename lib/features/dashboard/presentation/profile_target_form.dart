import 'package:flutter/material.dart';

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

  Widget _genderDrop(Color primary) => DropdownButtonFormField<Gender>(
    initialValue: gender,
    dropdownColor: primary,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    decoration: _decor('Jenis Kelamin'),
    items: const [
      DropdownMenuItem(value: Gender.male, child: Text('Pria')),
      DropdownMenuItem(value: Gender.female, child: Text('Wanita')),
    ],
    onChanged: (v) {
      if (v != null) onGenderChanged(v);
    },
  );

  Widget _activityDrop(Color primary) => DropdownButtonFormField<ActivityLevel>(
    initialValue: activity,
    dropdownColor: primary,
    isExpanded: true,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    decoration: _decor('Aktivitas'),
    items: ActivityLevel.values
        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
        .toList(),
    onChanged: (v) {
      if (v != null) onActivityChanged(v);
    },
  );

  Widget _input(TextEditingController ctrl, String lbl) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    decoration: _decor(lbl),
  );

  InputDecoration _decor(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontSize: 14,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.1),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white),
    ),
  );
}
