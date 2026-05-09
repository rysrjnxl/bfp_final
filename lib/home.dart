import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slider_button/slider_button.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'services/alarm_service.dart';
import 'widgets/fire_tile.dart';
import 'widgets/map_picker.dart';
import 'messages_screen.dart';
import 'main.dart';
import 'settings_screen.dart';
import 'services/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedFireType;
  String? _lastAlarmId;
  GlobalKey _sliderKey = GlobalKey();
  LatLng? _pickedLatLng; // stores the dropped pin coordinates

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AlarmService _alarmService = AlarmService();
  final User? user = FirebaseAuth.instance.currentUser;

  StreamSubscription? _alarmsSubscription;
  StreamSubscription? _fcmOpenedSubscription;

  String get _displayName =>
      (user?.displayName ?? user?.email?.split('@')[0] ?? 'User')
          .split(' ')
          .first;

  @override
  void initState() {
    super.initState();
    _listenForAlarms();
    _listenForFCMMessages();
  }

  void _listenForAlarms() {
    _alarmsSubscription = FirebaseFirestore.instance
        .collection('alarms')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted || snapshot.docs.isEmpty) return;

        final doc = snapshot.docs.first;
        final data = doc.data();
        final String alarmId = doc.id;

        if (alarmId == _lastAlarmId) return;

        final Timestamp? time = data['timestamp'] as Timestamp?;
        if (time == null) return;

        final bool isRecent =
            DateTime.now().difference(time.toDate()).inSeconds < 30;
        final String triggeredBy = data['triggeredBy'] ?? '';
        final bool isOtherUser = triggeredBy != (user?.displayName ?? '');

        if (isRecent && isOtherUser) {
          _lastAlarmId = alarmId;
          _ringPhone(
            data['fireType'] ?? 'Unknown Fire',
            data['location'] ?? 'Unknown Location',
            data['note'] ?? 'No additional notes',
            triggeredBy,
          );
        }
      },
      onError: (error) {
        debugPrint('Alarms stream error: $error');
      },
    );
  }

  void _listenForFCMMessages() {
    _fcmOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) return;
      _showAlertFromData(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && mounted) _showAlertFromData(message.data);
    });
  }

  void _showAlertFromData(Map<String, dynamic> data) {
    _showEmergencyOverlay(
      data['fireType'] ?? 'Unknown Fire',
      data['location'] ?? 'Unknown Location',
      data['note'] ?? 'No additional notes',
      data['triggeredBy'] ?? 'Unknown',
    );
  }

  Future<void> _ringPhone(
      String fireType, String location, String note, String triggeredBy) async {
    WakelockPlus.enable();

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final String selectedSound = settings.alarmSound;

      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/$selectedSound'));
    } catch (e) {
      debugPrint('🔊 Audio error: $e');
    }

    _showEmergencyOverlay(fireType, location, note, triggeredBy);
  }

  Future<void> _acknowledgeAlarm() async {
    await _audioPlayer.stop();
    WakelockPlus.disable();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _triggerAlarm() async {
    try {
      await _alarmService.triggerAlarm(
        fireType: _selectedFireType!,
        location: _locationController.text,
        note: _noteController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('🚨 ALARM POSTED TO STATION BOARD!'),
          duration: Duration(seconds: 3),
        ),
      );

      _noteController.clear();
      _locationController.clear();
      setState(() {
        _selectedFireType = null;
        _pickedLatLng = null;
        _sliderKey = GlobalKey();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post alert: $e')),
      );
      setState(() => _sliderKey = GlobalKey());
    }
  }

  Future<void> _handleLogout() async {
    await _alarmsSubscription?.cancel();
    await _fcmOpenedSubscription?.cancel();

    await _audioPlayer.stop();
    WakelockPlus.disable();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showEmergencyOverlay(
      String fireType, String location, String note, String triggeredBy) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚨 FIRE ALERT!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $fireType',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Location: $location',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            if (note.isNotEmpty) ...[
              Text('Note: $note',
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
            ],
            Text('Reported by: $triggeredBy',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text("ACKNOWLEDGE",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _acknowledgeAlarm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCenter() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "SELECT FIRE TYPE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    FireTile(
                      label: 'Residential Fire',
                      icon: Icons.home,
                      color: Colors.red,
                      isSelected: _selectedFireType == 'Residential Fire',
                      onTap: () => setState(
                          () => _selectedFireType = 'Residential Fire'),
                    ),
                    FireTile(
                      label: 'Building Fire',
                      icon: Icons.apartment,
                      color: Colors.orange,
                      isSelected: _selectedFireType == 'Building Fire',
                      onTap: () =>
                          setState(() => _selectedFireType = 'Building Fire'),
                    ),
                    FireTile(
                      label: 'Grass Fire',
                      icon: Icons.grass,
                      color: Colors.green,
                      isSelected: _selectedFireType == 'Grass Fire',
                      onTap: () =>
                          setState(() => _selectedFireType = 'Grass Fire'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 📍 FIRE LOCATION — taps open the map picker
              GestureDetector(
                onTap: () async {
                  final LatLng? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MapPickerScreen()),
                  );
                  if (result != null) {
                    setState(() {
                      _pickedLatLng = result;
                      _locationController.text =
                          '${result.latitude.toStringAsFixed(5)}, '
                          '${result.longitude.toStringAsFixed(5)}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Fire Location',
                      hintText: 'Tap to drop pin on map',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          const Icon(Icons.location_on, color: Colors.red),
                      suffixIcon: _pickedLatLng != null
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : const Icon(Icons.map, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 📝 ADDITIONAL NOTES FIELD
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Note/Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),

              KeyedSubtree(
                key: _sliderKey,
                child: SliderButton(
                  action: () async {
                    if (_selectedFireType == null) {
                      if (!mounted) return false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please select a fire type first!")),
                      );
                      return false;
                    }

                    if (_locationController.text.trim().isEmpty) {
                      if (!mounted) return false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Please drop a pin on the map first!")),
                      );
                      return false;
                    }

                    await _triggerAlarm();
                    return true;
                  },
                  label: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Color.fromARGB(255, 237, 86, 86),
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                    child: const Text("Slide to Alarm All"),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 30),
                  width: 270,
                  radius: 10,
                  buttonColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.5),
                  highlightedColor: Colors.red,
                  baseColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedIndex == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $_displayName',
                      style: const TextStyle(fontSize: 18)),
                ],
              )
            : _selectedIndex == 1
                ? const Text('Station Chat')
                : const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildControlCenter()
          : _selectedIndex == 1
              ? const MessagesScreen()
              : const SettingsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alarmsSubscription?.cancel();
    _fcmOpenedSubscription?.cancel();
    _audioPlayer.dispose();
    _noteController.dispose();
    super.dispose();
  }
}