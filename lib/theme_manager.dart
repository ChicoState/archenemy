import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._();

  ThemeMode _mode = ThemeMode.system;
  Color _seed = Colors.red;

  ThemeManager._();

  ThemeMode get mode => _mode;
  Color get seed => _seed;

  void updateMode(ThemeMode newMode) {
    if (newMode == _mode) return;
    _mode = newMode;
    notifyListeners();
  }

  void updateSeed(Color newSeed) {
    if (newSeed == _seed) return;
    _seed = newSeed;
    notifyListeners();
  }
}
