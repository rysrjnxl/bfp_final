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
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
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
  LatLng? _pickedLatLng;

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

  // inside lib/home.dart

  bool _isInitialLoad = true; // Add this flag to your State class

  void _listenForAlarms() {
    _alarmsSubscription = FirebaseFirestore.instance
        .collection('alarms')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted || snapshot.docs.isEmpty) return;

        // Skip the very first alarm that exists when the stream starts
        if (_isInitialLoad) {
          _isInitialLoad = false;
          final doc = snapshot.docs.first;
          _lastAlarmId = doc.id; // Mark this as the "seen" alarm
          return;
        }

        final doc = snapshot.docs.first;
        final data = doc.data();
        final String alarmId = doc.id;

        // Standard check to prevent double-firing
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
            latitude: data['latitude'] != null ? (data['latitude'] as num).toDouble() : null,
            longitude: data['longitude'] != null ? (data['longitude'] as num).toDouble() : null,
          );
        }
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
      fireType: data['fireType'] ?? 'Unknown Fire',
      location: data['location'] ?? 'Unknown Location',
      note: data['note'] ?? 'No additional notes',
      triggeredBy: data['triggeredBy'] ?? 'Unknown',
      // If your push notifications include lat/lng, you can add them here too:
      latitude: data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null,
      longitude: data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null,
    );
  }

  Future<void> _ringPhone(
    String fireType, String location, String note, String triggeredBy,
    {double? latitude, double? longitude}) async {
  WakelockPlus.enable();

  final settings = Provider.of<SettingsProvider>(context, listen: false);

  if (settings.vibrateOnAlert) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Vibrate for 1 second, pause for 1 second, repeat
        Vibration.vibrate(pattern: [1000, 1000, 1000, 1000, 1000, 1000], repeat: 0); 
      }
    }

  // ← Show overlay over other apps
  if (await FlutterOverlayWindow.isPermissionGranted()) {
    if (await FlutterOverlayWindow.isActive() == false) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: '🚨 FIRE ALERT',
        overlayContent: '$fireType at $location',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 500,
        width: WindowSize.matchParent,
      );
    }

    // Send data to overlay
    await FlutterOverlayWindow.shareData({
      'fireType': fireType,
      'location': location,
      'note': note,
      'triggeredBy': triggeredBy,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // Vibrate
  if (settings.vibrateOnAlert) {
    HapticFeedback.heavyImpact();
  }

  // Play alarm
  try {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/${settings.alarmSound}'));
  } catch (e) {
    debugPrint('🔊 Audio error: $e');
  }

  _showEmergencyOverlay(
    fireType: fireType,
    location: location,
    note: note,
    triggeredBy: triggeredBy,
    latitude: latitude,
    longitude: longitude
  );
}

  Future<void> _acknowledgeAlarm() async {
    await _audioPlayer.stop();
    WakelockPlus.disable();
    if (!mounted) return;

    Vibration.cancel();
  }

  Future<void> _triggerAlarm() async {
    try {
      await _alarmService.triggerAlarm(
        fireType: _selectedFireType!,
        location: _locationController.text,
        note: _noteController.text,
        latLng: _pickedLatLng, // ← ADD
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

  void _showEmergencyOverlay({
  required String fireType,
  required String location,
  required String note,
  required String triggeredBy,
  double? latitude, // Pass these from your notification or stream
  double? longitude,
}) {
  if (!mounted) return;

  // Create a LatLng object if coordinates are provided
  final LatLng? pinLocation = (latitude != null && longitude != null)
      ? LatLng(latitude, longitude)
      : null;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.red[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero, // Zero padding to allow map to hit edges
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black26,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    '🚨 FIRE ALERT!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // ── Map Preview ──
            SizedBox(
                height: 180,
                child: pinLocation != null
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: pinLocation,
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none, // ← non-interactive
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.bfp_final',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pinLocation,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No map data available',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
              ),

            // ── Details ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: $fireType',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Location: $location',
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Note: $note',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                  const SizedBox(height: 12),
                  Text('Reported by: $triggeredBy',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                 ],
                ),
             ),

            // ── Action ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text("ACKNOWLEDGE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[900],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _acknowledgeAlarm();
                    },
                  ),
                ),
             ),
            ],
          ),
        ),
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
                    FireTile(
                      label: 'Other',
                      icon: Icons.more_horiz,
                      color: const Color.fromARGB(255, 167, 167, 167),
                      isSelected: _selectedFireType == 'Other',
                      onTap: () =>
                          setState(() => _selectedFireType = 'Other'),
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
              GestureDetector(
                onTap: () async {
                  final Map<String, dynamic>? result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                  );
                  if (result != null) {
                    final LatLng location = result['location'] as LatLng;
                    final String address = result['address'] as String;
                    setState(() {
                      _pickedLatLng = location;
                      _locationController.text = address.isNotEmpty
                          ? address
                          : '${location.latitude.toStringAsFixed(5)}, '
                            '${location.longitude.toStringAsFixed(5)}';
                    });
                  }
                },
                child: AbsorbPointer( // ← ADD THIS
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Fire Location',
                      hintText: 'Tap to drop pin on map',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                      suffixIcon: _pickedLatLng != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
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