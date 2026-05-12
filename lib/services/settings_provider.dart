import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _alarmSound = 'alarm.mp3';
  bool _vibrateOnAlert = true; // ← ADD

  ThemeMode get themeMode => _themeMode;
  String get alarmSound => _alarmSound;
  bool get vibrateOnAlert => _vibrateOnAlert; // ← ADD

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    _alarmSound = prefs.getString('alarmSound') ?? 'alarm.mp3';
    _vibrateOnAlert = prefs.getBool('vibrateOnAlert') ?? true; // ← ADD
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

  void toggleVibrate(bool value) async { // ← ADD
    _vibrateOnAlert = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrateOnAlert', value);
  }
}