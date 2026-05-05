import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlarmService {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> triggerAlarm({
    required String fireType,
    required String note,
  }) async {
    await FirebaseFirestore.instance.collection('alarms').add({
      'fireType': fireType,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
      'triggeredBy': user?.displayName ?? 'Unknown',
    });
  }
}