import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_theme.dart';

class AppStyleController extends ChangeNotifier {
  static const _boxName = 'app_preferences_box';
  static const _keyStyle = 'app_visual_style';

  AppVisualStyle _style = AppVisualStyle.defaultStyle;

  AppVisualStyle get style => _style;

  ThemeData get themeData => AppTheme.light(style: _style);

  Future<void> load() async {
    final box = await _openBox();
    final raw = box.get(_keyStyle) as String?;
    if (raw == null) return;

    final saved = AppVisualStyle.values.where((e) => e.name == raw);
    if (saved.isEmpty) return;

    _style = saved.first;
    notifyListeners();
  }

  Future<void> setStyle(AppVisualStyle nextStyle) async {
    if (_style == nextStyle) return;
    _style = nextStyle;
    notifyListeners();

    final box = await _openBox();
    await box.put(_keyStyle, nextStyle.name);
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }
}
