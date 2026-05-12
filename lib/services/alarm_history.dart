import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AlarmHistoryPage extends StatelessWidget {
  const AlarmHistoryPage({super.key});

  void _showPreview(BuildContext context, Map<String, dynamic> data) {
    final DateTime dt = (data['timestamp'] as Timestamp).toDate();
    final String formattedDate =
        DateFormat('MMMM dd, yyyy - hh:mm a').format(dt);
    final String fireType = data['fireType'] ?? 'Unknown';
    final String location = data['location'] ?? 'Unknown Location';
    final String note = data['note'] ?? '';
    final String triggeredBy = data['triggeredBy'] ?? 'Unknown';
    final String status = data['status'] ?? 'Reported';

    // Try to parse lat/lng if stored, otherwise use default center
    LatLng? pinLocation;
    if (data['latitude'] != null && data['longitude'] != null) {
      pinLocation = LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                color: const Color.fromARGB(255, 183, 58, 58),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fireType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),

              // ── Mini Map ─────────────────────────────────────
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

              // ── Details ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.location_on, 'Location', location),
                    const SizedBox(height: 10),
                    _detailRow(Icons.access_time, 'Date & Time', formattedDate),
                    const SizedBox(height: 10),
                    _detailRow(Icons.person, 'Reported by', triggeredBy),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _detailRow(Icons.notes, 'Note', note),
                    ],
                    const SizedBox(height: 10),
                    _detailRow(
                      Icons.info_outline,
                      'Status',
                      status,
                      valueColor: Colors.red[900],
                    ),
                  ],
                ),
              ),

              // ── Close Button ─────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 183, 58, 58),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
    {Color? valueColor}) {
      return Builder(
        builder: (context) {
          final textColor = Theme.of(context).colorScheme.onSurface;
          final labelColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: labelColor),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: textColor),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: labelColor),
                      ),
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          color: valueColor ?? textColor,
                          fontWeight: valueColor != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm History'),
        backgroundColor: const Color.fromARGB(255, 183, 58, 58),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alarms')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No fire alerts recorded.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data()
                  as Map<String, dynamic>;

              final DateTime dt =
                  (data['timestamp'] as Timestamp).toDate();
              final String formattedDate =
                  DateFormat('MMMM dd, yyyy - hh:mm a').format(dt);

              // Fire type icon color
              final String fireType = data['fireType'] ?? '';
              final Color tileColor = fireType.contains('Grass')
                  ? Colors.green
                  : fireType.contains('Building')
                      ? Colors.orange
                      :fireType.contains('Residential')
                       ? Colors.red
                       : Colors.grey;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tileColor,
                    child: const Icon(Icons.local_fire_department,
                        color: Colors.white),
                  ),
                  title: Text(
                    fireType.isNotEmpty
                        ? fireType
                        : data['location'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['location'] ?? 'Unknown Location',
                          style: const TextStyle(fontSize: 12)),
                      Text(formattedDate,
                          style: const TextStyle(fontSize: 11)),
                      Text(
                        'Status: ${data['status'] ?? 'Reported'}',
                        style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showPreview(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }
}