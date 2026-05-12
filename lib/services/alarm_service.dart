import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlarmService {
  Future<void> triggerAlarm({
    required String fireType,
    required String location,
    required String note,
    double? lat,   // NEW: saved separately so overlay can read them
    double? lng,   // NEW
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final Map<String, dynamic> data = {
      'fireType': fireType,
      'location': location,
      'note': note,
      'triggeredBy': user?.displayName ?? user?.email ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Only include lat/lng if they were provided
    if (lat != null) data['lat'] = lat;
    if (lng != null) data['lng'] = lng;

    await FirebaseFirestore.instance.collection('alarms').add(data);
  }
}