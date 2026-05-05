import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlarmService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> triggerAlarm({
    required String fireType,
    required String note,
    required String location,
  }) async {
    await FirebaseFirestore.instance.collection('alarms').add({
      'fireType': fireType,
      'note': note,
      'location': location,
      'timestamp': FieldValue.serverTimestamp(),
      'triggeredBy': user?.displayName ?? 'Unknown',
    });
  }
}