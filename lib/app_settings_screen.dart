import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
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
          const _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.nightlight_round),
            value: settings.themeMode == ThemeMode.dark,
            activeThumbColor: const Color.fromARGB(255, 183, 58, 58),           // ← replace activeColor
            activeTrackColor: const Color.fromARGB(255, 183, 58, 58).withValues(alpha: 0.5),
            onChanged: settings.toggleTheme,
          ),
          const Divider(),

          const _SectionHeader(title: 'Alert Settings'),
          ListTile(
            title: const Text('Alarm Sound'),
            subtitle: Text('Current: ${_soundLabel(settings.alarmSound)}'),
            leading: const Icon(Icons.volume_up),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSoundPicker(context, settings),
          ),
          SwitchListTile(
            title: const Text('Vibrate on Alert'),
            subtitle: const Text('Vibrate when a fire alarm is triggered'),
            secondary: const Icon(Icons.vibration),
            value: settings.vibrateOnAlert,
            activeThumbColor: const Color.fromARGB(255, 183, 58, 58),
            activeTrackColor: const Color.fromARGB(255, 183, 58, 58).withValues(alpha: 0.5),
            onChanged: settings.toggleVibrate,
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _soundLabel(String file) {
    const map = {
      'alarm.mp3': 'Classic Alarm',
      'alarm2.mp3': 'Siren',
      'alarm3.mp3': 'Digital Alert',
      'alarm4.mp3': 'Alert',
    };
    return map[file] ?? file;
  }

  void _showSoundPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SoundPickerSheet(settings: settings),
    );
  }
}

// ── Sound Picker Sheet — stateful to manage audio player ──
class _SoundPickerSheet extends StatefulWidget {
  final SettingsProvider settings;
  const _SoundPickerSheet({required this.settings});

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingFile;

  final List<Map<String, String>> _sounds = const [
    {'name': 'Classic Alarm', 'file': 'alarm.mp3'},
    {'name': 'Whistle', 'file': 'alarm2.mp3'},
    {'name': 'Siren', 'file': 'alarm3.mp3'},
    {'name': 'Horn', 'file': 'alarm4.mp3'},
  ];

  Future<void> _playPreview(String file) async {
    await _player.stop();
    setState(() => _playingFile = file);
    await _player.play(AssetSource('audio/$file'));
    // Auto stop after 5 seconds
    await Future.delayed(const Duration(seconds: 7));
    if (mounted) {
      await _player.stop();
      setState(() => _playingFile = null);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Select Alarm Sound',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const Divider(height: 1),
        ..._sounds.map((sound) {
          final String file = sound['file']!;
          final String name = sound['name']!;
          final bool isSelected = widget.settings.alarmSound == file;
          final bool isPlaying = _playingFile == file;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? const Color.fromARGB(255, 183, 58, 58)
                  : Colors.grey[200],
              child: Icon(
                isPlaying ? Icons.stop : Icons.music_note,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: isPlaying
                ? const Text('Playing preview...',
                    style: TextStyle(
                        color: Color.fromARGB(255, 183, 58, 58),
                        fontSize: 11))
                : const Text('Tap to preview',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check,
                    color: Color.fromARGB(255, 183, 58, 58))
                : null,
            onTap: () async {
              // Preview sound
              await _playPreview(file);
            },
            onLongPress: () {
              // Long press to select
              widget.settings.setAlarmSound(file);
              _player.stop();
              Navigator.pop(context);
            },
          );
        }),
        // Select button for currently playing
        if (_playingFile != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text(
                    'Use ${_sounds.firstWhere((s) => s['file'] == _playingFile)['name']!}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 183, 58, 58),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.settings.setAlarmSound(_playingFile!);
                  _player.stop();
                  Navigator.pop(context);
                },
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Tap to preview • Long press to select',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}