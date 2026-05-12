import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';


class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  String _fireType = 'Fire Alert';
  String _location = 'Unknown Location';
  String _note = '';
  String _triggeredBy = '';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && mounted) {
        setState(() {
          _fireType = data['fireType'] ?? 'Fire Alert';
          _location = data['location'] ?? 'Unknown Location';
          _note = data['note'] ?? '';
          _triggeredBy = data['triggeredBy'] ?? '';
          _lat = data['lat'] as double?;
          _lng = data['lng'] as double?;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red[900],
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 32),
                  SizedBox(width: 10),
                  Text(
                    '🚨 FIRE ALERT!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Fire type
              Text(
                'Type: $_fireType',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.white70, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _location,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),

              // Map thumbnail
              if (_lat != null && _lng != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://staticmap.openstreetmap.de/staticmap.php'
                    '?center=$_lat,$_lng'
                    '&zoom=16&size=400x160'
                    '&markers=$_lat,$_lng,red-pushpin',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // FIX: renamed duplicate _ parameters
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Map unavailable',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                  ),
                ),
              ],

              if (_note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Note: $_note',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
              ],
              const SizedBox(height: 8),
              if (_triggeredBy.isNotEmpty)
                Text(
                  'Reported by: $_triggeredBy',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14),
                ),

              const SizedBox(height: 24),

              // Acknowledge button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('ACKNOWLEDGE',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await FlutterOverlayWindow.closeOverlay();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}