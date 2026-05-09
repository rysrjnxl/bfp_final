import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlarmService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> triggerAlarm({
    required String fireType,
    required String location,
    required String note,
    double? lat,
    double? lng,
  }) async {
    await FirebaseFirestore.instance.collection('alarms').add({
      'fireType': fireType,
      'location': location,
      'note': note,
      'lat': lat,
      'lng': lng,
      'triggeredBy': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}