import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _alarmSound = 'alarm.mp3';

  ThemeMode get themeMode => _themeMode;
  String get alarmSound => _alarmSound;

  SettingsProvider() {
    _loadSettings();
  }

  // Load saved settings on startup
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _alarmSound = prefs.getString('alarmSound') ?? 'alarm.mp3';
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
  }

  void setAlarmSound(String soundPath) async {
    _alarmSound = soundPath;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarmSound', soundPath);
  }
}