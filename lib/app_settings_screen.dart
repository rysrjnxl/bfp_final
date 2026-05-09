import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/settings_provider.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        children: [
          // Theme Toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.nightlight_round),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (bool value) => settings.toggleTheme(value),
          ),
          const Divider(),

          // Alarm Sound Picker
          ListTile(
            title: const Text('Alarm Sound'),
            subtitle: Text('Current: ${settings.alarmSound}'),
            leading: const Icon(Icons.volume_up),
            onTap: () {
              _showSoundPicker(context, settings);
            },
          ),
        ],
      ),
    );
  }

  void _showSoundPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _soundOption(context, settings, 'Classic Alarm', 'alarm.mp3'),
          _soundOption(context, settings, 'Siren', 'alarm2.mp3'),
          _soundOption(context, settings, 'Digital Alert', 'alarm3.mp3'),
          _soundOption(context, settings, 'Alert', 'alarm4.mp3'),
        ],
      ),
    );
  }

  Widget _soundOption(BuildContext context, SettingsProvider settings, String name, String file) {
    return ListTile(
      title: Text(name),
      trailing: settings.alarmSound == file ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        settings.setAlarmSound(file);
        Navigator.pop(context);
      },
    );
  }
}