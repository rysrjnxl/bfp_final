import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class AlarmService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> triggerAlarm({
  required String fireType,
  required String location,
  required String note,
  LatLng? latLng,
}) async {
  await FirebaseFirestore.instance.collection('alarms').add({
    'fireType': fireType,
    'location': location,
    'note': note,
    'timestamp': FieldValue.serverTimestamp(),
    'triggeredBy': user?.displayName ?? 'Unknown',
    'status': 'Reported',
    if (latLng != null) ...{
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    },
  });
}
}