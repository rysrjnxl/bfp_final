import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  String get _myName {
    final name = currentUser?.displayName;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : 'Unknown';
  }

  String get _myEmail => currentUser?.email ?? '';

  Stream<QuerySnapshot> getUsers() {
    return _firestore
        .collection('users')
        .where('email', isNotEqualTo: _myEmail)
        .snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> getConversations() {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: _myEmail)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['lastMessageTime'] as Timestamp?;
        final bTime = bData['lastMessageTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return docs;
    });
  }

  Future<String> getOrCreateDMConversation(
      String otherEmail, String otherName) async {
    final members = [_myEmail, otherEmail]..sort();
    final conversationId = members.join('_');

    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set({
        'id': conversationId,
        'type': 'direct',
        'members': members,
        'memberNames': {
          _myEmail: _myName,
          otherEmail: otherName,
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return conversationId;
  }

  Future<String> createGroupConversation(
      String groupName, List<Map<String, String>> selectedUsers) async {
    final members = [_myEmail, ...selectedUsers.map((u) => u['email']!)];
    final memberNames = <String, String>{
      _myEmail: _myName,
      for (var u in selectedUsers) u['email']!: u['name']!,
    };

    final doc = await _firestore.collection('conversations').add({
      'type': 'group',
      'name': groupName,
      'members': members,
      'memberNames': memberNames,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _myEmail,
    });

    return doc.id;
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderEmail': _myEmail,
      'senderName': _myName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final convRef =
        _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderName': _myName,
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots(includeMetadataChanges: false);
  }
}