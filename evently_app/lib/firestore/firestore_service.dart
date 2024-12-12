import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUser({
    required String uid,
    required String name,
    required String email,
    required String profilePicture,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'events': [],
    });
  }

  Future<void> addEvent({
    required String name,
    required DateTime date,
    required String location,
    required String createdByUid,
  }) async {
    await _firestore.collection('events').add({
      'name': name,
      'date': Timestamp.fromDate(date),
      'location': location,
      'createdBy': _firestore.doc('users/$createdByUid'),
      'participants': [],
      'tasks': [],
      'expenses': [],
    });
  }
}
