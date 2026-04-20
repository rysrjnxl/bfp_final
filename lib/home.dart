import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slider_button/slider_button.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

GlobalKey _sliderKey = GlobalKey();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _selectedFireType;
  final TextEditingController _noteController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('alarms')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        Timestamp? time = data['timestamp'] as Timestamp?;
        if (time != null) {
          DateTime alarmTime = time.toDate();
          if (DateTime.now().difference(alarmTime).inSeconds < 10) {
            if (data['triggeredBy'] != user?.displayName) {
              _ringPhone(data['fireType'], data['note']);
            }
          }
        }
      }
    });
  }

  void _ringPhone(String fireType, String note) {
    WakelockPlus.enable();
    _showEmergencyOverlay(fireType, note);
  }

  void _showEmergencyOverlay(String title, String body) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        content: Text(body,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          ElevatedButton(
            onPressed: () {
              WakelockPlus.disable();
              Navigator.pop(context);
            },
            child: const Text("ACKNOWLEDGE"),
          )
        ],
      ),
    );
  }

  Widget _buildFireTile(String label, IconData icon, Color color) {
    bool isSelected = _selectedFireType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFireType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 1), blurRadius: 10)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerAlarm() async {
    try {
      await FirebaseFirestore.instance.collection('alarms').add({
        'fireType': _selectedFireType,
        'note': _noteController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'triggeredBy': user?.displayName ?? 'Unknown',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('🚨 ALARM POSTED TO STATION BOARD!'),
        ),
      );

      _noteController.clear();
      setState(() => _selectedFireType = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post alert: $e')),
      );
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildControlCenter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "SELECT FIRE TYPE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildFireTile('Residential Fire', Icons.home, Colors.red),
                _buildFireTile('Building Fire', Icons.apartment, Colors.orange),
                _buildFireTile('Grass Fire', Icons.grass, Colors.green),
              ],
            ),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Location / Additional Notes',
              hintText: 'e.g. Brgy 4, near the church',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            key: _sliderKey,
            child: SliderButton(
              action: () async {
                if (_selectedFireType == null) {
                  if (!mounted) return false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select a fire type first!")),
                  );
                  return false;
                }
                await _triggerAlarm();
                if (!mounted) return true;
                  setState(() {
                    _sliderKey = GlobalKey();
                  });
                return true;
              },
              label: Text(
                "Slide to Alarm All",
                style: TextStyle(
                    color: Colors.red[900],
                    fontWeight: FontWeight.w500,
                    fontSize: 17),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = (user?.displayName ?? user?.email?.split('@')[0] ?? 'User')
    .split(' ')
    .first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, $displayName',
                style: const TextStyle(fontSize: 18)),
            const Row(
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 4),
                SizedBox(width: 4),
                Text('12 Personnel Online',
                    style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildControlCenter()
          : const Center(child: Text("Messages")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Messages'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}